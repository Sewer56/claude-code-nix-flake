{
  lib,
  pkgs,
}: {
  disabled = import ./disabled.nix;
  basic-commands = import ./basic-commands/basic-commands.nix;
  commands-dir = import ./commands-dir/commands-dir.nix;
  memory-text = import ./memory-text/memory-text.nix;
  memory-source = import ./memory-source/memory-source.nix;
  mcp-servers = import ./mcp-servers/mcp-servers.nix;
  claude-json = import ./claude-json/claude-json.nix;
  settings-json = import ./settings-json/settings-json.nix;
}
