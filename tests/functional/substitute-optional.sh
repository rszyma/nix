#!/usr/bin/env bash

source common.sh

TODO_NixOS # Requires substituting from a local binary cache, enable when we sign paths in NixOS tests
needLocalStore "'--no-require-sigs' can’t be used with the daemon"

outPath=$(nix-build dependencies.nix --no-out-link)
nix copy --to "file://$cacheDir" "$outPath"

# Make every lookup in the cache fail with an error instead of a miss.
for f in "$cacheDir"/*.narinfo; do
    echo garbage > "$f"
done

clearStore
clearCacheCache

expect 1 nix-build --substituters "file://$cacheDir" --no-require-sigs dependencies.nix --no-out-link

clearCacheCache

nix-build --substituters "file://$cacheDir?optional=true" --no-require-sigs dependencies.nix --no-out-link 2>&1 \
    | tee "$TEST_ROOT/log"
grepQuiet "^ignoring errors from optional substituter '.*': NAR info file .* is corrupt" "$TEST_ROOT/log"
# Reported once in total, not once per path, and not as a warning.
[[ $(grep -c "ignoring errors from optional substituter" "$TEST_ROOT/log") -eq 1 ]]
grepQuietInverse "warning:" "$TEST_ROOT/log"
[[ -e $outPath ]]

clearStore
clearCacheCache

nix-build --substituters "file://$cacheDir?optional=true" --no-require-sigs dependencies.nix --dry-run 2>&1 \
    | grepQuiet "will be built"

# Make every download from the cache fail, while lookups still succeed.
clearStore
clearBinaryCache
outPath=$(nix-build dependencies.nix --no-out-link)
nix copy --to "file://$cacheDir" "$outPath"
for f in "$cacheDir"/nar/*; do
    echo garbage > "$f"
done

clearStore
clearCacheCache

expect 1 nix-build --substituters "file://$cacheDir" --no-require-sigs dependencies.nix --no-out-link 2>&1 \
    | grepQuiet "some substitutes for the outputs of derivation"

clearStore
clearCacheCache

nix-build --substituters "file://$cacheDir?optional=true" --no-require-sigs dependencies.nix --no-out-link 2>&1 \
    | tee "$TEST_ROOT/log"
[[ $(grep -c "^ignoring errors from optional substituter" "$TEST_ROOT/log") -eq 1 ]]
[[ -e $outPath ]]
