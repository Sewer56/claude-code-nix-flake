{pkgs, ...}: {
  programs.claude-code = {
    enable = true;
    package = null;
    hooks = [
      (pkgs.writeScript "basic-hooks.sh" ''
        #!/usr/bin/env bash

        # Test hook script for verifying hooks functionality
        echo "Hook executed: $0"
        echo "Arguments: $@"

        # This is a test hook file for testing the hooks option
        exit 0
      '')
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.claude/hooks/basic-hooks.sh
    assertFileContent \
      home-files/.claude/hooks/basic-hooks.sh \
      ${./basic-hooks-expected.sh}
  '';
}
