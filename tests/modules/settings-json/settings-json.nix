{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.claude-code = {
    enable = true;
    package = null;
    # Test settings.json configuration
    # NOTE: This demonstrates REPLACEMENT behavior for nested objects/arrays.
    # The permissions.allow and permissions.deny arrays from the existing file
    # are completely REPLACED (not merged) with the new values specified here.
    # Only top-level fields like newField are merged/added to existing content.
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

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = let
    preexistingSettings = ./settings-json-input.json;
    expectedContent = ./settings-json-expected.json;
    settingsPath = ".claude/settings.json";
    activationScript = pkgs.writeScript "activation" config.home.activation.setupSettingsJsonConfig.data;
  in ''
    export HOME=$TMPDIR/hm-user

    # Simulate preexisting .claude/settings.json file
    mkdir -p $HOME/.claude
    cp ${preexistingSettings} $HOME/${settingsPath}

    # Set up environment and run the activation script
    export TMPDIR=$TMPDIR
    export DRY_RUN_CMD=""
    cp ${activationScript} $TMPDIR/activate
    chmod +x $TMPDIR/activate
    $TMPDIR/activate

    # Validate the merged settings
    assertFileExists "$HOME/${settingsPath}"
    assertFileContent "$HOME/${settingsPath}" "${expectedContent}"

    # Test idempotency
    $TMPDIR/activate
    assertFileExists "$HOME/${settingsPath}"
    assertFileContent "$HOME/${settingsPath}" "${expectedContent}"
  '';
}
