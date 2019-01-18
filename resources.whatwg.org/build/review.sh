#!/bin/bash
set -o nounset

# This script is maintained at
# https://github.com/whatwg/whatwg.org/tree/master/resources.whatwg.org/build and assumes English as
# your locale. See README.md there for documentation.

git checkout master
git checkout -b "review-draft-$(date +'%F')"

mkdir -p "review-drafts"
INPUT_FILE=$(find . -maxdepth 1 -name "*.bs" -print -quit)
REVIEW_DRAFT="review-drafts/$(date +'%Y-%m').bs"
# The backslash+linefeed literal is for sed.
# shellcheck disable=SC1004
sed 's/^Group: WHATWG$/&\
'"Date: $(date +'%Y-%m-%d')/g" < "$INPUT_FILE" > "$REVIEW_DRAFT"
echo "Created Review Draft at $REVIEW_DRAFT"
echo "Please verify that only one line changed relative to $INPUT_FILE:"
diff -up "$INPUT_FILE" "$REVIEW_DRAFT"

git add review-drafts/*
git commit -m "Review Draft Publication: $(date +'%B %G')"
