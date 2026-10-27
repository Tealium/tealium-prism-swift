#!/bin/bash
# Builds every product of the Swift package (TealiumPrism-Package scheme) for one destination.
# Used by the build_SPM job in .github/workflows/build-and-test.yml.
set -euo pipefail   # pipefail: a failing xcodebuild fails the script even though its output is piped
usage() { echo "usage: build_spm.sh <destination>" >&2; }
[ $# -eq 1 ] || { usage; exit 1; }
cd "$(dirname "$0")/.."
[ -f Package.swift ] || { echo "Package.swift not found" >&2; exit 1; }
# xcodebuild opens a workspace/project in the current folder before Package.swift, so refuse to run if one exists.
if compgen -G '*.xcworkspace' >/dev/null || compgen -G '*.xcodeproj' >/dev/null; then
  echo "xcworkspace/xcodeproj at repo root would shadow Package.swift" >&2; exit 1
fi
DESTINATION="$1"

args=(
  build
  -scheme TealiumPrism-Package             # auto-generated scheme: every product and target, including ones added later
  -destination "$DESTINATION"              # e.g. "generic/platform=iOS Simulator"
  -derivedDataPath build/spm               # build output inside the checkout (gitignored), empty on every CI run
  -onlyUsePackageVersionsFromResolvedFile  # use Package.resolved as committed; fail instead of re-resolving
  COMPILER_INDEX_STORE_ENABLE=NO           # skip the editor's code index: unused on CI and slows the build
  # Fail when a target imports a sibling it doesn't declare in Package.swift. Don't drop it: without it,
  # this is only caught by build order. Xcode 16 needs explicit modules for the check (default from Xcode 26).
  DIAGNOSE_MISSING_TARGET_DEPENDENCIES=YES_ERROR
  SWIFT_ENABLE_EXPLICIT_MODULES=YES
  -IDEBuildingContinueBuildingAfterErrors=YES  # report every broken module, not only the first
)

echo "Building TealiumPrism-Package for $DESTINATION"
# --renderer github-actions turns errors and warnings into GitHub annotations on the PR.
xcodebuild "${args[@]}" | xcbeautify --renderer github-actions
