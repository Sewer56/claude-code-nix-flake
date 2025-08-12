{
  pkgs,
  # lib,
  config,
  # inputs,
  ...
}: {
  # https://devenv.sh/basics/
  env.PROJECT_NAME = "Claude Code Nix";

  # https://devenv.sh/packages/
  packages = [pkgs.git];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.welcome.exec = ''
    echo "🚀 Welcome to the $PROJECT_NAME development environment!"
    echo ""
    echo "📦 This is a Home Manager module for Claude Code configuration"
    echo ""
    echo "🛠️  Available commands:"
    echo "  • format                - Format all Nix files manually"
    echo "  • run-tests             - Run NMT tests for the module"
    echo "  • run-test <name>       - Run a specific NMT test"
    echo "  • git-add               - Stage all changes (git add .)"
    echo "  • git-commit [message]  - Commit with message (git commit -m)"
    echo "  • git-push              - Push to remote (git push)"
    echo ""
    echo "📁 Key files:"
    echo "  • lib/claude-code.nix   - Main home-manager module"
    echo "  • lib/package.nix       - Package definition"
    echo "  • tests/                - NMT test suite"
    echo "  • devenv.nix           - Development environment config"
    echo ""
    echo "💡 Pro tip: Files are automatically formatted with Alejandra on git commit!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  '';

  scripts.format.exec = ''
    echo "🎨 Formatting all Nix files..."
    alejandra *.nix lib/*.nix
    echo "✅ Formatting complete!"
  '';

  scripts.git-add.exec = ''
    echo "📝 Staging all changes..."
    git add .
    git status --short
    echo "✅ Files staged!"
  '';

  scripts.git-commit.exec = ''
    if [ -z "$1" ]; then
      echo "❌ Please provide a commit message:"
      echo "   git-commit \"your message here\""
      exit 1
    fi
    echo "💾 Committing changes..."
    git commit -m "$1"
    echo "✅ Commit complete!"
  '';

  scripts.git-push.exec = ''
    echo "🚀 Pushing to remote..."
    git push
    echo "✅ Push complete!"
  '';

  scripts.run-tests.exec = ''
    echo "🧪 Running NMT tests for Claude Code module..."
    echo ""
    cd "${config.env.DEVENV_ROOT}/tests"
    nix run .#tests
  '';

  scripts.run-test.exec = ''
    if [ $# -eq 0 ]; then
      echo "❌ Error: Test name required"
      echo "Usage: run-test <test-name>"
      echo ""
      echo "Available tests:"
      echo "  • basic-agents"
      echo "  • basic-commands"
      echo "  • basic-hooks"
      echo "  • agents-dir"
      echo "  • claude-json"
      echo "  • commands-dir"
      echo "  • disabled"
      echo "  • hooks-dir"
      echo "  • mcp-servers"
      echo "  • memory-source"
      echo "  • memory-text"
      echo "  • settings-json"
      exit 1
    fi

    echo "🧪 Running NMT test: $1"
    echo ""
    cd "${config.env.DEVENV_ROOT}/tests"
    nix run ".#test-$1"
  '';

  enterShell = ''
    welcome
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/git-hooks/
  git-hooks.hooks.alejandra = {
    enable = true;
    description = "Nix code formatter";
  };

  # See full reference at https://devenv.sh/reference/options/
}
