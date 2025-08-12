{pkgs, ...}: {
  programs.claude-code = {
    enable = true;
    package = null;
    agents = [
      (pkgs.writeText "basic-agents.md" ''
        ---
        name: test-agent
        description: "Test agent for verifying agents functionality"
        tools: Read, Grep, Glob, Bash
        ---

        # Test Agent

        This is a test agent file for testing the agents option.

        You are a specialized test agent that helps verify the functionality
        of the Claude Code agents system.

        ## Instructions

        - Always respond with helpful testing information
        - Verify system functionality when requested
        - Report any issues found during testing

        Usage: This agent is used to test the agents configuration feature.
      '')
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.claude/agents/basic-agents.md
    assertFileContent \
      home-files/.claude/agents/basic-agents.md \
      ${./basic-agents-expected.md}
  '';
}
