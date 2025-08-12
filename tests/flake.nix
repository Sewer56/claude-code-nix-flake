{
  description = "Tests for claude-code Home Manager module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Import our test framework that uses Home Manager
        tests = import ./default.nix {
          inherit pkgs;
          home-manager = home-manager.outPath;
        };
      in {
        # Expose the test framework for running tests
        packages = {
          # All tests
          tests = tests.run.all;

          # Individual test packages (note: these need to be run with nix-shell)
          # Use: cd tests && nix-shell -A run.test-name
          test-disabled = tests.run.disabled;
          test-basic-agents = tests.run.basic-agents;
          test-basic-commands = tests.run.basic-commands;
          test-agents-dir = tests.run.agents-dir;
          test-claude-json = tests.run.claude-json;
          test-commands-dir = tests.run.commands-dir;
          test-mcp-servers = tests.run.mcp-servers;
          test-memory-source = tests.run.memory-source;
          test-memory-text = tests.run.memory-text;
          test-settings-json = tests.run.settings-json;
        };

        # Development shell for running tests
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix
            home-manager.packages.${system}.default
          ];

          shellHook = ''
            echo "Home Manager test environment for claude-code module"
            echo "Available commands:"
            echo "  nix run .#test-disabled      - Run disabled test"
            echo "  nix run .#test-basic-commands - Run basic commands test"
            echo "  nix run .#tests               - Run all tests"
          '';
        };
      }
    );
}
