{
  programs.claude-code.enable = false;

  nmt.script = ''
    assertPathNotExists home-files/.claude
  '';
}
