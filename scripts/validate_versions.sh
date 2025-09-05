#!/bin/bash
# A script to verify that the versions are correct
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

constants=$(<../tealium-swift/core/API/Misc/TealiumConstants.swift)
regex="^.*public static let libraryVersion \= \"([0-9\.]*)\""

if [[ $constants =~ $regex ]]
then
    versionConstant=${BASH_REMATCH[1]}
else
    echo "Couldn't match the library version, exiting"
    exit 1
fi
echo Version Constant "$versionConstant"

podspecFile=$(<../tealium-swift.podspec)
podspecRegex="^.*s.version[[:space:]]*\= \'([0-9\.]*)\'"

if [[ $podspecFile =~ $podspecRegex ]]
then
    podspecVersion=${BASH_REMATCH[1]}
else
    echo "Couldn't match the podspec version, exiting"
    exit 1
fi
echo Podspec Version "$podspecVersion"

if [ "$podspecVersion" != "$versionConstant" ]
then
    echo -e "The podspec version \"$podspecVersion\" is different from the version constant \"$versionConstant\".\nDid you forget to update one of the two?"
    exit 1
fi

echo -e "\nSuccess: All versions match!"