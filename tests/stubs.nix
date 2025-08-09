{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    lib.test.mkStubPackage = {name ? "claude-code"}:
      pkgs.runCommandLocal name {} ''
        mkdir -p $out/bin
        echo '#!${pkgs.runtimeShell}' > $out/bin/${name}
        echo 'echo "@${name}@"' >> $out/bin/${name}
        chmod +x $out/bin/${name}
      '';
  };
}
