#!/bin/bash
# Custom script to lint all configurations
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

errors=()
./lint.sh --config_file "../.swiftlint.yml" || errors+=("swiftlint.yml")
./lint.sh --config_file "../.swiftlint_test.yml" || errors+=("swiftlint_test.yml")

if [ ${#errors[@]} -eq 0 ]; then
    echo "All lints succeeded"
else
    echo "Some lints failed for:" "${errors[@]}"
    exit 1
fi