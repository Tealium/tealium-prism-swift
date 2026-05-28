#!/bin/bash

set -euo pipefail

# Resolve scripts dir and source the validator
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_ROOT="${SCRIPT_DIR}/.."
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/validate_versions.sh"

declare -a POSITIONAL_ARGS=()   # make sure array exists


while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
        OUTPUT="$2"
        shift # past argument
        shift # past value
        ;;
        -t|--theme)
        THEME="$2"
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

# Safely restore positional parameters, even if none
if ((${#POSITIONAL_ARGS[@]})); then
  set -- "${POSITIONAL_ARGS[@]}"
else
  set --
fi

VERSION="$(get_version)"
: "${THEME:=fullwidth}"
: "${OUTPUT:=_site}"

echo "Building Documentation for Version" "$VERSION"

cd "$REPO_ROOT" || { echo "cd failure" >&2; exit 1; }


bundle exec jazzy --clean --theme="${THEME}" --output="${OUTPUT}"