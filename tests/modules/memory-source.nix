{
  config,
  pkgs,
  ...
}: {
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {};
    memory.source = pkgs.writeText "memory-source.md" ''
      # Memory from Source File

      This content comes from a source file and should be copied to CLAUDE.md.

      Some additional content for testing purposes.
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.claude/CLAUDE.md
    assertFileContent \
      home-files/.claude/CLAUDE.md \
      ${./memory-source-expected.md}
  '';
}
