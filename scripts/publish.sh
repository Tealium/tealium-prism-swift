#!/bin/bash
set -euo pipefail

PUSH=false                      # optional flag, default off
declare -a POSITIONAL_ARGS=()   # make sure array exists

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--push)
        PUSH=true
        shift # consume flag
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

# Resolve scripts dir and source the validator
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/validate_versions.sh"

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean. Commit or stash your changes first." >&2
  exit 1
fi

versionConstant="$(get_version)"

git fetch --tags

if ! currentTag=$(git describe --tags --exact-match HEAD 2>/dev/null)
then
  echo "HEAD is not currently at a tag. Please create and check out a tag matching the version constant (${versionConstant}) before publishing."
  exit 1
fi

echo "Current tag $currentTag"
if [ "$currentTag" != "$versionConstant" ]
then
  printf "The current tag \"%s\" is different from the version constant \"%s\".\nDid you forget to add the tag to the release or did you forget to update the Constant?\n" "$currentTag" "$versionConstant"
  exit 1
fi

echo "All checks are passed, ready to release to CocoaPods"

if [ "$PUSH" = true ]
then
    bundle exec pod trunk push
else
    echo "Do you wish to publish to CocoaPods?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) echo "Ok, running \"bundle exec pod trunk push\" now."; bundle exec pod trunk push; break;;
            No ) echo "Ok, skip the release for now."; exit;;
        esac
    done
fi

