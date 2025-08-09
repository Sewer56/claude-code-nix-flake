{
  config,
  pkgs,
  ...
}: {
  programs.claude-code = {
    enable = true;
    package = null;
    commands = [
      (pkgs.writeText "test-command.md" ''
        # Test Command

        This is a test command file for testing the commands option.

        Usage: Run this test command to verify functionality.
      '')
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.claude/commands/test-command.md
    assertFileContent \
      home-files/.claude/commands/test-command.md \
      ${./basic-commands-expected.md}
  '';
}
