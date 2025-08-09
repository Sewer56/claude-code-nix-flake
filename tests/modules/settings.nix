{
  config,
  pkgs,
  ...
}: {
  # Pre-create a reference .claude.json file with existing settings
  home.file.".claude.json" = {
    text = builtins.toJSON {
      theme = "light";
      autoUpdates = true;
      numStartups = 100;
      tipsHistory = {
        "new-user-warmup" = 5;
        "shift-enter" = 10;
        "existing-tip" = 1;
      };
      mcpServers = {
        existing-server = {
          type = "stdio";
          command = "existing-command";
        };
      };
    };
  };

  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {};
    # Test general settings override
    settings = {
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
    # Test that mcpServers still works alongside settings
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

  nmt.script = ''
    assertFileExists home-files/.claude.json

    # Check that top-level settings were overridden
    if ! ${pkgs.jq}/bin/jq -e '.theme == "dark-daltonized"' home-files/.claude.json > /dev/null; then
      echo "ERROR: theme was not overridden to dark-daltonized"
      exit 1
    fi

    if ! ${pkgs.jq}/bin/jq -e '.autoUpdates == false' home-files/.claude.json > /dev/null; then
      echo "ERROR: autoUpdates was not overridden to false"
      exit 1
    fi

    # Check that new top-level fields were added
    if ! ${pkgs.jq}/bin/jq -e '.newTopLevelField == "test-value"' home-files/.claude.json > /dev/null; then
      echo "ERROR: newTopLevelField was not added"
      exit 1
    fi

    if ! ${pkgs.jq}/bin/jq -e '.fallbackAvailableWarningThreshold == 0.2' home-files/.claude.json > /dev/null; then
      echo "ERROR: fallbackAvailableWarningThreshold was not set"
      exit 1
    fi

    # Check that nested objects were properly merged (not replaced)
    # tipsHistory should contain both existing and new values
    if ! ${pkgs.jq}/bin/jq -e '.tipsHistory."new-user-warmup" == 1' home-files/.claude.json > /dev/null; then
      echo "ERROR: tipsHistory.new-user-warmup was not overridden to 1"
      exit 1
    fi

    if ! ${pkgs.jq}/bin/jq -e '.tipsHistory."shift-enter" == 201' home-files/.claude.json > /dev/null; then
      echo "ERROR: tipsHistory.shift-enter was not overridden to 201"
      exit 1
    fi

    if ! ${pkgs.jq}/bin/jq -e '.tipsHistory."memory-command" == 194' home-files/.claude.json > /dev/null; then
      echo "ERROR: tipsHistory.memory-command was not added"
      exit 1
    fi

    # Check that existing nested values are preserved when not overridden
    if ! ${pkgs.jq}/bin/jq -e '.tipsHistory."existing-tip" == 1' home-files/.claude.json > /dev/null; then
      echo "ERROR: existing tipsHistory.existing-tip was not preserved"
      exit 1
    fi

    # Check that existing top-level fields are preserved when not overridden
    if ! ${pkgs.jq}/bin/jq -e '.numStartups == 100' home-files/.claude.json > /dev/null; then
      echo "ERROR: existing numStartups was not preserved"
      exit 1
    fi

    # Check that mcpServers still works alongside settings
    if ! ${pkgs.jq}/bin/jq -e '.mcpServers."test-server"' home-files/.claude.json > /dev/null; then
      echo "ERROR: test-server from mcpServers was not found"
      exit 1
    fi

    # Check that existing mcpServers are preserved
    if ! ${pkgs.jq}/bin/jq -e '.mcpServers."existing-server"' home-files/.claude.json > /dev/null; then
      echo "ERROR: existing-server from original config was not preserved"
      exit 1
    fi

    # Verify the test-server has correct configuration
    if ! ${pkgs.jq}/bin/jq -e '.mcpServers."test-server".command == "test-command"' home-files/.claude.json > /dev/null; then
      echo "ERROR: test-server command was not set correctly"
      exit 1
    fi
  '';
}
