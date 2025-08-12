{
  # config,
  pkgs,
  ...
}: let
  agentsDir = pkgs.runCommandLocal "agents-dir" {} ''
            mkdir -p $out
            cat > $out/agents-dir-agent1.md << 'EOF'
    ---
    name: agent1
    description: "First test agent"
    tools: Read, Grep
    ---

    # Agent 1

    This is the first agent in the agents directory.

    You are a specialized code review agent that focuses on:
    - Code quality analysis
    - Best practices recommendations
    - Security vulnerability detection

    Example usage: Use this agent for automated code reviews.
    EOF
            cat > $out/agents-dir-agent2.md << 'EOF'
    ---
    name: agent2
    description: "Second test agent"
    tools: Bash, Glob
    ---

    # Agent 2

    This is the second agent in the agents directory.

    You are a deployment and infrastructure agent that helps with:
    - Environment setup
    - CI/CD pipeline management
    - System administration tasks

    Example usage: Use this agent for deployment automation.
    EOF
  '';
in {
  programs.claude-code = {
    enable = true;
    package = null;
    agentsDir = agentsDir;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/agents/agents-dir-agent1.md
    assertFileExists home-files/.claude/agents/agents-dir-agent2.md
    assertFileContent \
      home-files/.claude/agents/agents-dir-agent1.md \
      ${./agents-dir-agent1-expected.md}
    assertFileContent \
      home-files/.claude/agents/agents-dir-agent2.md \
      ${./agents-dir-agent2-expected.md}
  '';
}
