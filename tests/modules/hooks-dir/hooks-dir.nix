{
  # config,
  pkgs,
  ...
}: let
  hooksDir = pkgs.runCommandLocal "hooks-dir" {} ''
            mkdir -p $out
            cat > $out/hooks-dir-hook1.sh << 'EOF'
    #!/usr/bin/env bash

    # Pre-tool hook for bash commands
    echo "Pre-tool hook executing for bash command"
    echo "Command: $1"

    # Validate bash command (example)
    if [[ "$1" == *"rm -rf"* ]]; then
        echo "Dangerous command blocked!"
        exit 1
    fi

    exit 0
    EOF
            cat > $out/hooks-dir-hook2.sh << 'EOF'
    #!/usr/bin/env bash

    # Post-tool hook for file operations
    echo "Post-tool hook executing for file operation"
    echo "File modified: $1"

    # Auto-format or validate file (example)
    if [[ "$1" == *.json ]]; then
        echo "JSON file detected, validating format..."
    fi

    exit 0
    EOF
            chmod +x $out/*.sh
  '';
in {
  programs.claude-code = {
    enable = true;
    package = null;
    hooksDir = hooksDir;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/hooks/hooks-dir-hook1.sh
    assertFileExists home-files/.claude/hooks/hooks-dir-hook2.sh
    assertFileContent \
      home-files/.claude/hooks/hooks-dir-hook1.sh \
      ${./hooks-dir-hook1-expected.sh}
    assertFileContent \
      home-files/.claude/hooks/hooks-dir-hook2.sh \
      ${./hooks-dir-hook2-expected.sh}
  '';
}
