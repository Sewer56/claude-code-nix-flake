{
  config,
  pkgs,
  ...
}: {
  # Pre-create a reference .claude.json file
  home.file.".claude.json" = {
    text = builtins.toJSON {
      theme = "dark-daltonized";
      mcpServers = {
        github = {
          type = "stdio";
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
            GITHUB_PERSONAL_ACCESS_TOKEN = "";
          };
        };
      };
    };
  };

  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {};
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

    # Check that the test-server was added
    if ! ${pkgs.jq}/bin/jq -e '.mcpServers."test-server"' home-files/.claude.json > /dev/null; then
      echo "ERROR: test-server not found in merged JSON"
      exit 1
    fi

    # Check that original servers are preserved
    if ! ${pkgs.jq}/bin/jq -e '.mcpServers.github' home-files/.claude.json > /dev/null; then
      echo "ERROR: Original github server not preserved"
      exit 1
    fi

    # Check that non-mcpServers fields are preserved
    if ! ${pkgs.jq}/bin/jq -e '.theme' home-files/.claude.json > /dev/null; then
      echo "ERROR: Original theme field not preserved"
      exit 1
    fi
  '';
}
