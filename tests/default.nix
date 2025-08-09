# Trying to do same as home-manager here.
# nmt is a neat testing framework, but it's quite a bit undocumented!
# Trying to stick to what home-manager does https://home-manager.dev/manual/25.05/index.xhtml#sec-tests
#
# home-files directory is some home-manager specific shenanigans.
{pkgs ? import <nixpkgs> {}}: let
  nmtSrc = fetchTarball {
    url = "https://git.sr.ht/~rycee/nmt/archive/v0.5.1.tar.gz";
    sha256 = "0qhn7nnwdwzh910ss78ga2d00v42b0lspfd7ybl61mpfgz3lmdcj";
  };

  modules = [
    ../lib/claude-code.nix
    ./stubs.nix
  ];
in
  import nmtSrc {
    inherit pkgs;
    lib = pkgs.lib;

    modules =
      modules
      ++ [
        # Basic home-manager configuration
        # Not actually used. Just mandatory.
        {
          home.username = "testuser";
          home.homeDirectory = "/home/testuser";
          home.stateVersion = "25.05";
        }
      ];

    testedAttrPath = []; # Mandatory
    tests = import ./modules;
  }
