{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.claude-code;
  baseDir =
    if cfg._testBasePath != null
    then cfg._testBasePath
    else "$HOME";
in {
  options.programs.claude-code = {
    enable = mkEnableOption "Claude Code configuration";

    commands = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of file paths to be copied to ~/.claude/commands/. These take precedence over files from commandsDir.";
    };

    commandsDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Directory containing command files (markdown) to be copied to ~/.claude/commands/. Individual commands specified in the commands option will take precedence over files with the same name from this directory.";
    };

    agents = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of file paths to be copied to ~/.claude/agents/. These take precedence over files from agentsDir.";
    };

    agentsDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Directory containing agent files (markdown) to be copied to ~/.claude/agents/. Individual agents specified in the agents option will take precedence over files with the same name from this directory.";
    };

    hooks = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of file paths to be copied to ~/.claude/hooks/. These take precedence over files from hooksDir.";
    };

    hooksDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Directory containing hook files (shell scripts) to be copied to ~/.claude/hooks/. Individual hooks specified in the hooks option will take precedence over files with the same name from this directory.";
    };

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.claude-code;
      defaultText = literalExpression "pkgs.claude-code";
      description = "The Claude Code package to use. Set to null to not install any package.";
    };

    memory = mkOption {
      default = {};
      description = "Configuration for Claude's memory file at ~/.claude/CLAUDE.md";
      type = types.submodule {
        options = {
          text = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "String content to write to ~/.claude/CLAUDE.md. If both text and source are provided, source takes precedence.";
          };

          source = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to a file whose content will be copied to ~/.claude/CLAUDE.md. Takes precedence over text if both are provided.";
          };
        };
      };
    };

    mcpServers = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = ''
        An attrset of MCP server configurations to merge into ~/.claude.json.
        The entire attrset will be merged into the JSON file as the "mcpServers" field.
        Supports all JSON data types including nested objects, arrays, strings, numbers, and booleans.
        Claude needs to be able to write to this file, so it is not directly managed by Nix.
      '';
      example = literalExpression ''
        {
          github = {
            command = "docker";
            args = [
              "run"
              "-i"
              "--rm"
              "-e"
              "GITHUB_PERSONAL_ACCESS_TOKEN"
              "ghcr.io/github/github-mcp-server"
            ];
            env = {
              GITHUB_PERSONAL_ACCESS_TOKEN = "MY-TOKEN";
            };
          };
        }
      '';
    };

    claudeJson = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = ''
        An attrset of settings to merge into ~/.claude.json.
        Supports all JSON data types including nested objects.
        Can override both top-level and nested fields.
        Claude needs to be able to write to this file, so it is not directly managed by Nix.
      '';
      example = literalExpression ''
        {
          theme = "dark-daltonized";
          autoUpdates = false;
          tipsHistory = {
            "new-user-warmup" = 1;
            "shift-enter" = 201;
          };
        }
      '';
    };

    settingsJson = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = ''
        An attrset of settings to merge into ~/.claude/settings.json.
        Supports all JSON data types including nested objects.
        Can override both top-level and nested fields.
        Claude needs to be able to write to this file, so it is not directly managed by Nix.
      '';
      example = literalExpression ''
        {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
          permissions = {
            allow = [
              "WebFetch(domain:example.com)"
              "Bash(mkdir:*)"
            ];
            deny = [
              "Bash(rm:*)"
            ];
          };
        }
      '';
    };

    forceClean = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to clean out existing files before applying configuration.
        When true, the module will remove all files in ~/.claude/commands/
        and delete ~/.claude/CLAUDE.md before copying/creating new files.
      '';
    };

    skipBackup = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to skip backing up existing files before applying configuration.
        When true, the module will not create backup files with the specified extension.
      '';
    };

    _testBasePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      internal = true;
      description = "Internal option for testing. Sets base path instead of $HOME.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.memory.source == null || cfg.memory.text == null;
        message = "Set only one of memory.source or memory.text, not both";
      }
    ];

    home.packages = lib.optional (cfg.package != null) cfg.package;

    home.activation.backupExistingClaudeFiles = mkIf (!cfg.skipBackup) (
      lib.hm.dag.entryAfter ["linkGeneration"] ''
        CLAUDE_DIR="${baseDir}/.claude"
        CLAUDE_MEMORY_FILE="$CLAUDE_DIR/CLAUDE.md"

        BACKUP_EXT="''${HOME_MANAGER_BACKUP_EXT:-hm-bak}"
        echo "Using backup extension: .$BACKUP_EXT"

        ${
          if cfg.memory.source != null || cfg.memory.text != null
          then ''
            if [ -f "$CLAUDE_MEMORY_FILE" ]; then
              echo "Backing up existing memory file..."
              $DRY_RUN_CMD mv "$CLAUDE_MEMORY_FILE" "$CLAUDE_MEMORY_FILE.$BACKUP_EXT"
            fi
          ''
          else ""
        }

        ${
          if cfg.commands != [] || cfg.commandsDir != null
          then ''
            CLAUDE_COMMANDS_DIR="$CLAUDE_DIR/commands"
            if [ -d "$CLAUDE_COMMANDS_DIR" ]; then
              echo "Backing up existing commands directory..."
              $DRY_RUN_CMD mv "$CLAUDE_COMMANDS_DIR" "$CLAUDE_COMMANDS_DIR.$BACKUP_EXT"
            fi
          ''
          else ""
        }

        ${
          if cfg.agents != [] || cfg.agentsDir != null
          then ''
            CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"
            if [ -d "$CLAUDE_AGENTS_DIR" ]; then
              echo "Backing up existing agents directory..."
              $DRY_RUN_CMD mv "$CLAUDE_AGENTS_DIR" "$CLAUDE_AGENTS_DIR.$BACKUP_EXT"
            fi
          ''
          else ""
        }

        ${
          if cfg.hooks != [] || cfg.hooksDir != null
          then ''
            CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
            if [ -d "$CLAUDE_HOOKS_DIR" ]; then
              echo "Backing up existing hooks directory..."
              $DRY_RUN_CMD mv "$CLAUDE_HOOKS_DIR" "$CLAUDE_HOOKS_DIR.$BACKUP_EXT"
            fi
          ''
          else ""
        }
      ''
    );

    home.activation.forceCleanClaudeConfig = mkIf cfg.forceClean (
      lib.hm.dag.entryAfter ["linkGeneration"] ''
        CLAUDE_DIR="${baseDir}/.claude"
        CLAUDE_MEMORY_FILE="$CLAUDE_DIR/CLAUDE.md"
        CLAUDE_COMMANDS_DIR="$CLAUDE_DIR/commands"

        ${
          if cfg.memory.source != null || cfg.memory.text != null
          then ''
            if [ -f "$CLAUDE_MEMORY_FILE" ]; then
              echo "Cleaning memory file..."
              $DRY_RUN_CMD rm -f "$CLAUDE_MEMORY_FILE"
            fi
          ''
          else ""
        }

        ${
          if cfg.commands != [] || cfg.commandsDir != null
          then ''
            if [ -d "$CLAUDE_COMMANDS_DIR" ]; then
              echo "Cleaning up existing commands directory..."
              $DRY_RUN_CMD rm -rf "$CLAUDE_COMMANDS_DIR"
            fi
          ''
          else ""
        }

        ${
          if cfg.agents != [] || cfg.agentsDir != null
          then ''
            CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"
            if [ -d "$CLAUDE_AGENTS_DIR" ]; then
              echo "Cleaning up existing agents directory..."
              $DRY_RUN_CMD rm -rf "$CLAUDE_AGENTS_DIR"
            fi
          ''
          else ""
        }

        ${
          if cfg.hooks != [] || cfg.hooksDir != null
          then ''
            CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
            if [ -d "$CLAUDE_HOOKS_DIR" ]; then
              echo "Cleaning up existing hooks directory..."
              $DRY_RUN_CMD rm -rf "$CLAUDE_HOOKS_DIR"
            fi
          ''
          else ""
        }
      ''
    );

    home.activation.setupClaudeCommands = lib.hm.dag.entryAfter ["linkGeneration"] ''
      CLAUDE_DIR="${baseDir}/.claude"
      CLAUDE_COMMANDS_DIR="$CLAUDE_DIR/commands"

      # Create the directory if it doesn't exist with proper permissions
      $DRY_RUN_CMD mkdir -p "$CLAUDE_COMMANDS_DIR"
      # Ensure the directory is usable by forcing permissions
      $DRY_RUN_CMD install -d -m 0755 "$CLAUDE_COMMANDS_DIR"

      # First, copy markdown files from commandsDir if specified
      ${
        if cfg.commandsDir != null
        then ''
          # Find all .md files and copy them using install to set permissions properly
          for CMD_FILE in $(find "${cfg.commandsDir}" -type f -name "*.md"); do
            DEST_FILE="$CLAUDE_COMMANDS_DIR/$(basename "$CMD_FILE")"
            $DRY_RUN_CMD install -m 0644 "$CMD_FILE" "$DEST_FILE"
          done
        ''
        else ''
          # No commandsDir specified, skipping
        ''
      }

      ${concatMapStringsSep "\n" (
          commandPath: let
            filename = builtins.baseNameOf commandPath;
            parts = builtins.match "^[^-]+-(.*)$" filename;
            finalName =
              if parts == null
              then filename
              else builtins.elemAt parts 0;
          in ''
            $DRY_RUN_CMD install -m 0644 "${commandPath}" "$CLAUDE_COMMANDS_DIR/${finalName}"
          ''
        )
        cfg.commands}
    '';

    home.activation.setupClaudeAgents = lib.hm.dag.entryAfter ["linkGeneration"] ''
      CLAUDE_DIR="${baseDir}/.claude"
      CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"

      # Create the directory if it doesn't exist with proper permissions
      $DRY_RUN_CMD mkdir -p "$CLAUDE_AGENTS_DIR"
      # Ensure the directory is usable by forcing permissions
      $DRY_RUN_CMD install -d -m 0755 "$CLAUDE_AGENTS_DIR"

      # First, copy markdown files from agentsDir if specified
      ${
        if cfg.agentsDir != null
        then ''
          # Find all .md files and copy them using install to set permissions properly
          for AGENT_FILE in $(find "${cfg.agentsDir}" -type f -name "*.md"); do
            DEST_FILE="$CLAUDE_AGENTS_DIR/$(basename "$AGENT_FILE")"
            $DRY_RUN_CMD install -m 0644 "$AGENT_FILE" "$DEST_FILE"
          done
        ''
        else ''
          # No agentsDir specified, skipping
        ''
      }

      ${concatMapStringsSep "\n" (
          agentPath: let
            filename = builtins.baseNameOf agentPath;
            parts = builtins.match "^[^-]+-(.*)$" filename;
            finalName =
              if parts == null
              then filename
              else builtins.elemAt parts 0;
          in ''
            $DRY_RUN_CMD install -m 0644 "${agentPath}" "$CLAUDE_AGENTS_DIR/${finalName}"
          ''
        )
        cfg.agents}
    '';

    home.activation.setupClaudeHooks = lib.hm.dag.entryAfter ["linkGeneration"] ''
      CLAUDE_DIR="${baseDir}/.claude"
      CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"

      # Create the directory if it doesn't exist with proper permissions
      $DRY_RUN_CMD mkdir -p "$CLAUDE_HOOKS_DIR"
      # Ensure the directory is usable by forcing permissions
      $DRY_RUN_CMD install -d -m 0755 "$CLAUDE_HOOKS_DIR"

      # First, copy hook files from hooksDir if specified
      ${
        if cfg.hooksDir != null
        then ''
          # Find all files and copy them using install to set permissions properly
          for HOOK_FILE in $(find "${cfg.hooksDir}" -type f); do
            DEST_FILE="$CLAUDE_HOOKS_DIR/$(basename "$HOOK_FILE")"
            $DRY_RUN_CMD install -m 0755 "$HOOK_FILE" "$DEST_FILE"
          done
        ''
        else ''
          # No hooksDir specified, skipping
        ''
      }

      ${concatMapStringsSep "\n" (
          hookPath: let
            filename = builtins.baseNameOf hookPath;
            parts = builtins.match "^[^-]+-(.*)$" filename;
            finalName =
              if parts == null
              then filename
              else builtins.elemAt parts 0;
          in ''
            $DRY_RUN_CMD install -m 0755 "${hookPath}" "$CLAUDE_HOOKS_DIR/${finalName}"
          ''
        )
        cfg.hooks}
    '';

    home.activation.setupClaudeMemory = lib.hm.dag.entryAfter ["linkGeneration"] ''
      CLAUDE_DIR="${baseDir}/.claude"
      CLAUDE_MEMORY_FILE="$CLAUDE_DIR/CLAUDE.md"

      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR"
      $DRY_RUN_CMD install -d -m 0755 "$CLAUDE_DIR"

      # Handle memory configuration
      ${
        if cfg.memory.source != null
        then ''
          $DRY_RUN_CMD install -m 0644 "${cfg.memory.source}" "$CLAUDE_MEMORY_FILE"
        ''
        else if cfg.memory.text != null
        then ''
                    # Use a temporary file and install to ensure proper permissions
                    TEMP_FILE=$($DRY_RUN_CMD mktemp)
                    $DRY_RUN_CMD cat > "$TEMP_FILE" << 'EOF'
          ${cfg.memory.text}
          EOF
                    $DRY_RUN_CMD install -m 0644 "$TEMP_FILE" "$CLAUDE_MEMORY_FILE"
                    $DRY_RUN_CMD rm -f "$TEMP_FILE"
        ''
        else ''
          # Neither source nor text was set, do nothing
        ''
      }
    '';

    home.activation.setupClaudeJsonConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
      CLAUDE_DIR="${baseDir}/.claude"
      CLAUDE_CONFIG_FILE="${baseDir}/.claude.json"

      # Create directory if it doesn't exist with proper permissions
      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR"
      # Ensure the directory is usable by forcing permissions
      $DRY_RUN_CMD install -d -m 0755 "$CLAUDE_DIR"

      # If either mcpServers or claudeJson configuration is not empty
      ${
        if cfg.mcpServers != {} || cfg.claudeJson != {}
        then ''
                    # Check if the config file exists
                    if [ -f "$CLAUDE_CONFIG_FILE" ]; then
                      # Read existing JSON config
                      EXISTING_CONFIG=$($DRY_RUN_CMD cat "$CLAUDE_CONFIG_FILE" || echo "{}")
                    else
                      # Create a new config with empty object
                      EXISTING_CONFIG="{}"
                    fi

                    # Create a temporary file with the new configuration
                    NEW_CONFIG=$(cat <<'EOF'
          ${builtins.toJSON (cfg.claudeJson
            // (
              if cfg.mcpServers != {}
              then {mcpServers = cfg.mcpServers;}
              else {}
            ))}
          EOF
                    )

                    # Merge the configurations (preserving existing content and adding/updating new settings)
                    # Use jq's recursive merge operator * to handle nested objects properly
                    MERGED_CONFIG=$($DRY_RUN_CMD ${pkgs.jq}/bin/jq -s '.[0] * .[1]' <(echo "$EXISTING_CONFIG") <(echo "$NEW_CONFIG"))

                    # Write the merged configuration to a temp file first
                    TEMP_FILE=$($DRY_RUN_CMD mktemp)
                    $DRY_RUN_CMD echo "$MERGED_CONFIG" > "$TEMP_FILE"

                    # Use install to set permissions and copy the file
                    $DRY_RUN_CMD install -m 0644 "$TEMP_FILE" "$CLAUDE_CONFIG_FILE"
                    $DRY_RUN_CMD rm -f "$TEMP_FILE"
        ''
        else ''
          # No JSON configuration specified, do nothing
        ''
      }
    '';

    home.activation.setupSettingsJsonConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
      CLAUDE_DIR="${baseDir}/.claude"
      SETTINGS_FILE="$CLAUDE_DIR/settings.json"

      # Create directory if needed
      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR"
      $DRY_RUN_CMD install -d -m 0755 "$CLAUDE_DIR"

      # Handle settings.json configuration
      ${
        if cfg.settingsJson != {}
        then ''
                    # Check if the settings file exists
                    if [ -f "$SETTINGS_FILE" ]; then
                      EXISTING_SETTINGS=$($DRY_RUN_CMD cat "$SETTINGS_FILE" || echo "{}")
                    else
                      EXISTING_SETTINGS="{}"
                    fi

                    # Create new settings
                    NEW_SETTINGS=$(cat <<'EOF'
          ${builtins.toJSON cfg.settingsJson}
          EOF
                    )

                    # Merge settings
                    MERGED_SETTINGS=$($DRY_RUN_CMD ${pkgs.jq}/bin/jq -s '.[0] * .[1]' <(echo "$EXISTING_SETTINGS") <(echo "$NEW_SETTINGS"))

                    # Write merged settings
                    TEMP_FILE=$($DRY_RUN_CMD mktemp)
                    $DRY_RUN_CMD echo "$MERGED_SETTINGS" > "$TEMP_FILE"
                    $DRY_RUN_CMD install -m 0644 "$TEMP_FILE" "$SETTINGS_FILE"
                    $DRY_RUN_CMD rm -f "$TEMP_FILE"
        ''
        else ''
          # No settings.json configuration specified
        ''
      }
    '';
  };
}
