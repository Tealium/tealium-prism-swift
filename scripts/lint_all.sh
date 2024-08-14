#!/bin/bash
# Custom script to lint all configurations
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

./lint.sh --config_file "../.swiftlint.yml"
./lint.sh --config_file "../.swiftlint_test.yml"
