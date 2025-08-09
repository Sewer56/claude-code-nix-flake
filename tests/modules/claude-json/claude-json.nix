{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.claude-code = {
    enable = true;
    package = null;
    # Test general settings override using claudeJson
    # NOTE: This demonstrates REPLACEMENT behavior for nested objects.
    # The tipsHistory object from the existing file is completely REPLACED
    # (not merged) with the new tipsHistory object specified here.
    # Top-level fields are merged/added to existing content.
    claudeJson = {
      theme = "dark-daltonized";
      autoUpdates = false;
      fallbackAvailableWarningThreshold = 0.2;
      tipsHistory = {
        "new-user-warmup" = 1;
        "shift-enter" = 201;
        "memory-command" = 194;
      };
      newTopLevelField = "test-value";
    };
    # Test that mcpServers still works alongside claudeJson
    # The mcpServers object gets REPLACED, but individual servers are merged
    mcpServers = {
      test-server = {
        type = "stdio";
        command = "test-command";
        args = ["--test-mode"];
        env = {
          TEST_VAR = "test-value";
        };
      };
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = let
    preexistingConfig = ./claude-json-input.json;
    expectedContent = ./claude-json-expected.json;
    configPath = ".claude.json";
    activationScript = pkgs.writeScript "activation" config.home.activation.setupClaudeJsonConfig.data;
  in ''
    export HOME=$TMPDIR/hm-user

    # Simulate preexisting .claude.json file
    mkdir -p $HOME
    cp ${preexistingConfig} $HOME/${configPath}

    # Set up environment and run the activation script
    export TMPDIR=$TMPDIR
    export DRY_RUN_CMD=""
    cp ${activationScript} $TMPDIR/activate
    chmod +x $TMPDIR/activate
    $TMPDIR/activate

    # Validate the merged configuration
    assertFileExists "$HOME/${configPath}"
    assertFileContent "$HOME/${configPath}" "${expectedContent}"

    # Test idempotency
    $TMPDIR/activate
    assertFileExists "$HOME/${configPath}"
    assertFileContent "$HOME/${configPath}" "${expectedContent}"
  '';
}
