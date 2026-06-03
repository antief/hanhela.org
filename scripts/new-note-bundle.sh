#!/usr/bin/env sh
set -eu

# Backwards-compatible wrapper. Notes were folded back into posts.
exec sh "$(dirname "$0")/new-post-bundle.sh" "$@"
