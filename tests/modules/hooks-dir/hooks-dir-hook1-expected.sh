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
