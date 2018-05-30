#!/bin/bash
set -o errexit
set -o nounset

# This script is maintained at
# https://github.com/whatwg/whatwg.org/tree/master/resources.whatwg.org/build.
# See README.md there for documentation.

mkdir -p "review-drafts"
INPUT_FILE=$(find . -maxdepth 1 -name "*.bs" -print -quit)
REVIEW_DRAFT="review-drafts/$(date +'%Y-%m').bs"
# The backslash+linefeed literal is for sed.
# shellcheck disable=SC1004
sed 's/^Group: WHATWG$/&\
'"Date: $(date +'%Y-%m-%d')/g" < "$INPUT_FILE" > "$REVIEW_DRAFT"
echo "Created Review Draft at $REVIEW_DRAFT"
echo "Please verify that only one line changed relative to $INPUT_FILE:"
diff -up "$INPUT_FILE" "$REVIEW_DRAFT" || exit 0
