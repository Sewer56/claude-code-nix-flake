{config, ...}: {
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {};
    memory.text = ''
      # Memory from Text

      This is test memory content set via the text option.
      It should be written to CLAUDE.md.
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.claude/CLAUDE.md
    assertFileContent \
      home-files/.claude/CLAUDE.md \
      ${./memory-text-expected.md}
  '';
}
