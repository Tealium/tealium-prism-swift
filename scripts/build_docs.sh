#!/bin/bash
# Custom script to build a specific target
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }


POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
        VERSION="$2"
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

podspecFile=$(<../tealium-swift.podspec)
podspecRegex="^.*s.version[[:space:]]*\= \'([0-9\.]*)\'"

if [[ $podspecFile =~ $podspecRegex ]]
then
    podspecVersion=${BASH_REMATCH[1]}
fi

if [ -z "${VERSION}" ];     
then
    if [ -z "${podspecVersion}" ];
    then
        echo "Couldn't match the podspec version and no --version parameter provided, exiting."
        exit 1
    else
        VERSION=${BASH_REMATCH[1]}    
    fi
else
    if [ "${podspecVersion}" != "${VERSION}" ];
    then
        echo "Podspec version" "${podspecVersion}" "is different from provided version" "${VERSION}," "proceeding with the latter."
    fi
fi

echo "Building Documentation for Version" "$VERSION"

cd ..

bundle exec jazzy --clean