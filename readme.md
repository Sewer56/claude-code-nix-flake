# Deprecated

This flake has been upstreamed to `home-manager` as `programs.claude-code`, now that `claude-code` has had the symlink issue fixed.
This repository is no longer maintained, use the upstream package.

# Claude Nix

A Nix flake that provides a home-manager module for configuring Claude Code.

Fork of [flyinggrizzly/claude-nix](https://github.com/flyinggrizzly/claude-nix), since former appears
to be unmaintained.

## Features

- Install the Claude Code CLI package (optional)
- Configure command files in `~/.claude/commands/` by passing a directory and/or a list of individual files
- Configure agent files in `~/.claude/agents/` by passing a directory and/or a list of individual files
- Configure hook files in `~/.claude/hooks/` by passing a directory and/or a list of individual files
- Manage Claude memory in `~/.claude/CLAUDE.md`
- Configure MCP servers in `~/.claude.json`
- Support for standalone home-manager
- Follows the `-b <backup-ext>` flag

## Quick Start

Add this flake to your inputs:

```nix
{
  inputs = {
    # ...
    claude-code-nix-flake.url = "github:Sewer56/claude-code-nix-flake";
  };
}
```

and a simple config:

```nix
{ ... }:
{
  config = {
    imports = [
      inputs.claude-code-nix-flake.homeManagerModules.claude-code
    ];

    programs.claude-code = {
      enable = true;
      commandsDir = ./command-directory;
      commands = [ ./path/to/extra/command.md ];
      agentsDir = ./agent-directory;
      agents = [ ./path/to/extra/agent.md ];
      hooksDir = ./hook-directory;
      hooks = [ ./path/to/extra/hook.sh ];
      memory.source = ./my/claude.md;
      mcpServers = {
        github = {
          command = "docker";
          args = ["run" "-i" "--rm" "-e" "GITHUB_PERSONAL_ACCESS_TOKEN" "ghcr.io/github/github-mcp-server"];
          env = {
            # Don't store this as plain text. Use like, agenix or sops-nix or sumthing
            GITHUB_PERSONAL_ACCESS_TOKEN = "TOKEN";
          };
        };
      };
      claudeJson = {
        theme = "dark-daltonized";
        autoUpdates = false;
        tipsHistory = {
          "new-user-warmup" = 1;
          "shift-enter" = 201;
        };
      };
      settingsJson = {
        permissions = {
          allow = [
            "WebFetch(domain:github.com)"
            "Bash(mkdir:*)"
          ];
          deny = [];
        };
      };
    };
  }
}
```

## Configuration Options

| Option          | Type          | Default            | Description                                                          |
| --------------- | ------------- | ------------------ | -------------------------------------------------------------------- |
| `enable`        | boolean       | `false`            | Enable Claude Code configuration management                          |
| `package`       | package       | `pkgs.claude-code` | The Claude Code package to install                                   |
| `commands`      | list of paths | `[]`               | Command files to install in `~/.claude/commands/`                    |
| `commandsDir`   | path          | `null`             | Directory containing command files to install                        |
| `agents`        | list of paths | `[]`               | Agent files to install in `~/.claude/agents/`                        |
| `agentsDir`     | path          | `null`             | Directory containing agent files to install                          |
| `hooks`         | list of paths | `[]`               | Hook files to install in `~/.claude/hooks/`                          |
| `hooksDir`      | path          | `null`             | Directory containing hook files to install                           |
| `memory.text`   | string        | `null`             | Content to write to `~/.claude/CLAUDE.md`                            |
| `memory.source` | path          | `null`             | File to copy to `~/.claude/CLAUDE.md` (takes precedence over `text`) |
| `mcpServers`    | attrset       | `{}`               | MCP server configurations to merge into `~/.claude.json`             |
| `claudeJson`    | attrset       | `{}`               | General settings to merge into `~/.claude.json`                      |
| `settingsJson`  | attrset       | `{}`               | Configuration to merge into `~/.claude/settings.json`                |
| `forceClean`    | boolean       | `false`            | Clean existing files before applying configuration                   |
| `skipBackup`    | boolean       | `false`            | Skip backing up existing files before applying configuration         |

>[!CAUTION]
> Due to a [Claude bug with symlinked files](https://github.com/anthropics/claude-code/issues/764), this module copies files instead of symlinking them. **Removed commands, agents, and hooks won't be deleted from your config** unless you use `forceClean=true`.
>
> **Warning:** `forceClean` deletes ALL existing commands, agents, and hooks (including non-Nix ones) before adding new ones. Create backups first.

>[!WARNING] 
> **Configuration files are modified in-place.** This module directly edits your existing Claude Code configuration files.
>
> Claude actively writes to `~/.claude.json` and `~/.claude/settings.json` so they can't be directly managed by Nix.

## JSON Configuration Merging Behaviour

When using `claudeJson` and `settingsJson` options, the module uses **replacement behaviour** for nested objects and arrays, not deep merging:

- **Top-level fields**: New fields are added, existing fields are updated
- **Nested objects/arrays**: Completely replaced with new values (not merged)

### Example

If your existing `~/.claude/settings.json` contains:
```json
{
  "existingField": "existing-value",
  "permissions": {
    "allow": ["WebFetch(domain:existing.com)", "Bash(existing-command:*)"],
    "deny": ["Bash(rm:*)"]
  }
}
```

And your Nix configuration specifies:
```nix
settingsJson = {
  permissions = {
    allow = ["WebFetch(domain:example.com)", "Bash(mkdir:*)"];
    deny = ["Bash(rm -rf:*)"];
  };
  newField = "new-value";
};
```

The result will be:
```json
{
  "existingField": "existing-value",
  "newField": "new-value",
  "permissions": {
    "allow": ["WebFetch(domain:example.com)", "Bash(mkdir:*)"],
    "deny": ["Bash(rm -rf:*)"]
  }
}
```

Note how:
- ✅ Top-level `existingField` is preserved
- ✅ Top-level `newField` is added  
- ⚠️  `permissions.allow` array is **completely replaced** (old values lost)
- ⚠️  `permissions.deny` array is **completely replaced** (old values lost)

This behaviour ensures predictable configuration management where your Nix specification defines the exact state of nested structures.

## Development

This project uses [devenv](https://devenv.sh) for the development environment. To get started:

### Prerequisites

Install devenv by following the [getting started guide](https://devenv.sh/getting-started/).

### Setup

```bash
# Clone the repository
git clone https://github.com/Sewer56/claude-code-nix-flake.git
cd claude-code-nix-flake

# Enter the development environment (will install dependencies automatically)
devenv shell
# You may want to use e.g. `devenv shell zsh`, to enter non-bash shells.
```

### Code Editor Support

Look at the [Code Editor Support](https://devenv.sh/editor-support/vscode/) section of the
devenv documentation for how to set up your editor.

Basically:

1. Install `direnv`.
2. Install extension.

### Automatic Formatting

All Nix files are automatically formatted with [Alejandra](https://github.com/kamadorueda/alejandra) when you commit changes within the shell. You can also format manually using the `format` command.

For more information about devenv, see the [official documentation](https://devenv.sh).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. Claude itself has
proprietary licensing, plus nix and home-manager have their own shit. Go look it up.
