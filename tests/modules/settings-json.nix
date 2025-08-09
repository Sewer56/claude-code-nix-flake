{
  config,
  pkgs,
  ...
}: {
  # Pre-create a reference settings.json file with existing settings
  home.file.".claude/settings.json" = {
    text = builtins.toJSON {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
      permissions = {
        allow = [
          "WebFetch(domain:existing.com)"
          "Bash(existing-command:*)"
        ];
        deny = [
          "Bash(rm:*)"
        ];
      };
      existingField = "existing-value";
    };
  };

  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {};
    # Test settings.json configuration
    settingsJson = {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
      permissions = {
        allow = [
          "WebFetch(domain:example.com)"
          "Bash(mkdir:*)"
          "Bash(ls:*)"
        ];
        deny = [
          "Bash(rm -rf:*)"
        ];
      };
      newField = "new-value";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/settings.json

    # Check that permissions were merged correctly
    if ! ${pkgs.jq}/bin/jq -e '.permissions.allow | contains(["WebFetch(domain:example.com)"])' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: WebFetch(domain:example.com) permission not found"
      exit 1
    fi

    if ! ${pkgs.jq}/bin/jq -e '.permissions.allow | contains(["Bash(mkdir:*)"])' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: Bash(mkdir:*) permission not found"
      exit 1
    fi

    if ! ${pkgs.jq}/bin/jq -e '.permissions.allow | contains(["Bash(ls:*)"])' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: Bash(ls:*) permission not found"
      exit 1
    fi

    # Check that existing permissions are preserved
    if ! ${pkgs.jq}/bin/jq -e '.permissions.allow | contains(["WebFetch(domain:existing.com)"])' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: existing WebFetch permission was not preserved"
      exit 1
    fi

    if ! ${pkgs.jq}/bin/jq -e '.permissions.allow | contains(["Bash(existing-command:*)"])' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: existing Bash permission was not preserved"
      exit 1
    fi

    # Check deny permissions were merged
    if ! ${pkgs.jq}/bin/jq -e '.permissions.deny | contains(["Bash(rm -rf:*)"])' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: Bash(rm -rf:*) deny permission not found"
      exit 1
    fi

    # Check that existing deny permissions are preserved
    if ! ${pkgs.jq}/bin/jq -e '.permissions.deny | contains(["Bash(rm:*)"])' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: existing Bash(rm:*) deny permission was not preserved"
      exit 1
    fi

    # Check that schema was set correctly
    if ! ${pkgs.jq}/bin/jq -e '."$schema" == "https://json.schemastore.org/claude-code-settings.json"' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: schema was not set correctly"
      exit 1
    fi

    # Check that new fields were added
    if ! ${pkgs.jq}/bin/jq -e '.newField == "new-value"' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: newField was not added"
      exit 1
    fi

    # Check that existing fields are preserved
    if ! ${pkgs.jq}/bin/jq -e '.existingField == "existing-value"' home-files/.claude/settings.json > /dev/null; then
      echo "ERROR: existing field was not preserved"
      exit 1
    fi
  '';
}
