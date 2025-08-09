# Tests for claude-code Home Manager module using Home Manager's test framework
{
  pkgs ? import <nixpkgs> {},
  enableBig ? true,
  enableLegacyIfd ? false,
  home-manager ? /home/sewer/projects/home-manager,
}: let
  # Import Home Manager's extended lib and test setup
  lib = import "${home-manager}/modules/lib/stdlib-extended.nix" pkgs.lib;

  nmtSrc = fetchTarball {
    url = "https://git.sr.ht/~rycee/nmt/archive/v0.5.1.tar.gz";
    sha256 = "0qhn7nnwdwzh910ss78ga2d00v42b0lspfd7ybl61mpfgz3lmdcj";
  };

  # Import Home Manager's modules and add our claude-code module
  modules =
    import "${home-manager}/modules/modules.nix" {
      inherit lib pkgs;
      check = false;
    }
    ++ [
      # Add our claude-code module
      ../lib/claude-code.nix

      # Add test configuration module
      ({...}: {
        _module.args = {
          pkgs = lib.mkImageMediaOverride pkgs;
        };

        # Test user configuration - required for our tests
        home = {
          username = "hm-user";
          homeDirectory = "/home/hm-user";
          stateVersion = lib.mkDefault "24.05";
        };

        test.enableBig = enableBig;
        test.enableLegacyIfd = enableLegacyIfd;
      })

      # Test helper module: create home.file entries for NMT testing.
      # The project edits files in place. This creates the temporary dummies to test against.
      ({
        config,
        lib,
        ...
      }: let
        cfg = config.programs.claude-code;
      in {
        home.file = lib.mkIf cfg.enable (
          # Command files
          (lib.listToAttrs (lib.map (
              commandPath: let
                filename = builtins.baseNameOf commandPath;
                parts = builtins.match "^[^-]+-(.*)$" filename;
                finalName =
                  if parts == null
                  then filename
                  else builtins.elemAt parts 0;
              in {
                name = ".claude/commands/${finalName}";
                value = {source = commandPath;};
              }
            )
            cfg.commands))
          // (lib.optionalAttrs (cfg.commandsDir != null) (
            # Files from commandsDir
            lib.listToAttrs (lib.concatMap (
              cmdFile: let
                basename = builtins.baseNameOf cmdFile;
              in
                if lib.hasSuffix ".md" basename
                then [
                  {
                    name = ".claude/commands/${basename}";
                    value = {source = "${cfg.commandsDir}/${basename}";};
                  }
                ]
                else []
            ) (lib.attrNames (builtins.readDir cfg.commandsDir)))
          ))
          // (lib.optionalAttrs (cfg.memory.text != null) {
            # Memory from text
            ".claude/CLAUDE.md".text = cfg.memory.text;
          })
          // (lib.optionalAttrs (cfg.memory.source != null) {
            # Memory from source
            ".claude/CLAUDE.md".source = cfg.memory.source;
          })
          # Note: JSON files need custom merging logic, handled in individual tests
        );
      })
    ];
in
  import nmtSrc {
    inherit lib pkgs modules;
    testedAttrPath = [
      "home"
      "activationPackage"
    ];
    tests = import ./modules {inherit lib pkgs;};
  }
