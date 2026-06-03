#!/usr/bin/env sh
set -eu

usage() {
  echo "Usage: $0 my-post-slug" >&2
  echo "Slug must use lowercase letters, numbers and hyphens only." >&2
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

NAME="$1"

case "$NAME" in
  *[!a-z0-9-]*|''|-*|*-|*--*)
    usage
    exit 1
    ;;
esac

YEAR="${YEAR:-$(date +%Y)}"
case "$YEAR" in
  ''|*[!0-9]*)
    echo "Error: YEAR must be numeric" >&2
    exit 1
    ;;
esac

TARGET="content/posts/${YEAR}/${NAME}"

if [ -e "$TARGET" ]; then
  echo "Error: $TARGET already exists" >&2
  exit 1
fi

mkdir -p "$TARGET"
DATE="$(date -Iseconds)"
TITLE="$(printf '%s' "$NAME" | tr '-' ' ' | awk '{ for (i=1; i<=NF; i++) { $i=toupper(substr($i,1,1)) substr($i,2) } print }')"

cat > "$TARGET/index.en.md" <<EOF_INNER
---
title: "${TITLE}"
date: ${DATE}
draft: true
description: ""
slug: "${NAME}"
translationKey: "${NAME}"
categories: []
tags: []
---

Write the English post here.
EOF_INNER

cat > "$TARGET/index.fi.md" <<EOF_INNER
---
title: "${TITLE}"
date: ${DATE}
draft: true
description: ""
slug: "${NAME}"
translationKey: "${NAME}"
categories: []
tags: []
---

Kirjoita suomenkielinen versio tähän.
EOF_INNER

printf 'Created %s\n' "$TARGET"
