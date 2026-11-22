#!/usr/bin/env bash

source common.sh

# shellcheck disable=SC1111
needLocalStore "“--no-require-sigs” can’t be used with the daemon"

# No input derivations, so the build trace key does not change on resolution.
# shellcheck disable=SC2016
expr='with import ./config.nix; mkDerivation {
    name = "ca-optional";
    __contentAddressed = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    buildCommand = "echo hello > $out";
}'

buildDrv () {
    nix build --impure --expr "$expr" --no-link --no-require-sigs "$@"
}

clearStore
clearBinaryCache
nix copy --to "file://$cacheDir" --impure --expr "$expr"

# Make every build trace lookup in the cache fail with an error instead of a miss.
for f in "$cacheDir"/build-trace-v2/*/*.doi; do
    echo '{}' > "$f"
done

clearStore
clearCacheCache

expect 1 buildDrv --substituters "file://$cacheDir" --dry-run
expect 1 buildDrv --substituters "file://$cacheDir"

clearCacheCache

buildDrv --substituters "file://$cacheDir" --fallback --dry-run 2>&1 | grepQuiet "will be built"

clearCacheCache

buildDrv --substituters "file://$cacheDir?optional=true" --dry-run 2>&1 | grepQuiet "will be built"

clearCacheCache

buildDrv --substituters "file://$cacheDir?optional=true" 2>&1 | tee "$TEST_ROOT/log"
grepQuiet "^ignoring errors from optional substituter" "$TEST_ROOT/log"
nix store build-trace info --impure --expr "$expr"
