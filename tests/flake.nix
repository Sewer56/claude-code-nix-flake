{
  description = "Tests for claude-code Home Manager module";

  inputs = {
    # Reference the parent flake to inherit its locked versions
    parent-flake = {
      url = "path:..";
    };

    nixpkgs.follows = "parent-flake/nixpkgs";
    home-manager.follows = "parent-flake/home-manager";
    flake-utils.follows = "parent-flake/flake-utils";
  };

  outputs = {
    # These 2 args are needed to inherit the parent. Please leave them as is.
    self,
    parent-flake,
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

          # Individual test packages
          test-disabled = tests.run.disabled;
          test-basic-agents = tests.run.basic-agents;
          test-basic-commands = tests.run.basic-commands;
          test-basic-hooks = tests.run.basic-hooks;
          test-agents-dir = tests.run.agents-dir;
          test-claude-json = tests.run.claude-json;
          test-commands-dir = tests.run.commands-dir;
          test-hooks-dir = tests.run.hooks-dir;
          test-mcp-servers = tests.run.mcp-servers;
          test-memory-source = tests.run.memory-source;
          test-memory-text = tests.run.memory-text;
          test-settings-json = tests.run.settings-json;
        };

        # Make tests runnable as apps with wrapper scripts
        # NMT will complain if we use the flake based `nix run` or `nix shell`,
        # so we have to wrap each test in a legacy style script.
        apps = let
          mkTestApp = testName:
            flake-utils.lib.mkApp {
              drv = pkgs.writeShellScriptBin "run-${testName}" ''
                echo "Running ${testName} test using locked home-manager version..."
                nix-shell --expr '
                  let
                    pkgs = import <nixpkgs> {};
                    tests = import ./default.nix {
                      inherit pkgs;
                      home-manager = "${home-manager.outPath}";
                    };
                  in tests.run.${testName}
                '
              '';
            };
        in {
          tests = mkTestApp "all";
          test-disabled = mkTestApp "disabled";
          test-basic-agents = mkTestApp "basic-agents";
          test-basic-commands = mkTestApp "basic-commands";
          test-agents-dir = mkTestApp "agents-dir";
          test-claude-json = mkTestApp "claude-json";
          test-commands-dir = mkTestApp "commands-dir";
          test-mcp-servers = mkTestApp "mcp-servers";
          test-memory-source = mkTestApp "memory-source";
          test-memory-text = mkTestApp "memory-text";
          test-settings-json = mkTestApp "settings-json";
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
