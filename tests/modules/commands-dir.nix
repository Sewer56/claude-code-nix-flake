{
  config,
  pkgs,
  ...
}: let
  commandsDir = pkgs.runCommandLocal "commands-dir" {} ''
        mkdir -p $out
        cat > $out/cmd1.md << 'EOF'
    # Command 1

    This is the first command in the commands directory.

    Example usage: `cmd1 --help`
    EOF
        cat > $out/cmd2.md << 'EOF'
    # Command 2

    This is the second command in the commands directory.

    Example usage: `cmd2 --verbose`
    EOF
  '';
in {
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {};
    commandsDir = commandsDir;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/commands/cmd1.md
    assertFileExists home-files/.claude/commands/cmd2.md
    assertFileContent \
      home-files/.claude/commands/cmd1.md \
      ${./commands-dir-cmd1-expected.md}
    assertFileContent \
      home-files/.claude/commands/cmd2.md \
      ${./commands-dir-cmd2-expected.md}
  '';
}
