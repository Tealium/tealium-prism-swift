#!/bin/bash
# Custom script to build a specific target
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

./docs.sh --theme ./docs/tealdocs-theme/ \
    --output ~/Code/documentation-integrations/tealdocs/static/swift/ 
