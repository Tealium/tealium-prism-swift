#!/bin/bash
# Custom script to lint with a specific configuration
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config_file)
        CONFIG_FILE="$2"
        shift # past argument
        shift # past value
        ;;
        --*|-*)
        echo "Unknown option $1"
        exit 1
        ;;
        *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ -z "$CONFIG_FILE" ]
then
    echo "--config_file is NULL, make sure to pass it"
    exit 1
fi

bundle exec fastlane run swiftlint config_file:"${CONFIG_FILE}"
