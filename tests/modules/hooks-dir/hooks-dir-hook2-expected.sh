#!/usr/bin/env bash

# Post-tool hook for file operations
echo "Post-tool hook executing for file operation"
echo "File modified: $1"

# Auto-format or validate file (example)
if [[ "$1" == *.json ]]; then
    echo "JSON file detected, validating format..."
fi

exit 0
