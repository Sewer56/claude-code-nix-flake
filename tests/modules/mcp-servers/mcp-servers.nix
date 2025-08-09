{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.claude-code = {
    enable = true;
    package = null;
    # Test MCP servers configuration
    # NOTE: This demonstrates REPLACEMENT behaviour for the mcpServers object.
    # The entire mcpServers object from the existing file is merged with new servers,
    # but individual server configurations completely replace any existing ones with the same name.
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
    preexistingConfig = ./mcp-servers-input.json;
    expectedContent = ./mcp-servers-expected.json;
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
