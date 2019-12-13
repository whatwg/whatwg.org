#!/bin/bash
set -o errexit
set -o nounset

# This script is maintained at
# https://github.com/whatwg/whatwg.org/tree/master/resources.whatwg.org/build and assumes English as
# your locale. See README.md there for documentation.
#
# Please keep this synchronized with https://github.com/whatwg/html/blob/master/review-draft.sh.

header() {
  echo ""
  echo -e "\\x1b[1m$1\\x1b[0m"
  echo ""
}

header "Creating a git branch with a Review Draft:"

git checkout -b "review-draft-$(date +'%F')"

mkdir -p "review-drafts"
INPUT_FILE=$(find . -maxdepth 1 -name "*.bs" -print -quit)
REVIEW_DRAFT="review-drafts/$(date +'%Y-%m').bs"
# The backslash+linefeed literal is for sed.
# shellcheck disable=SC1004
sed 's/^Group: WHATWG$/&\
'"Date: $(date +'%Y-%m-%d')/g" < "$INPUT_FILE" > "$REVIEW_DRAFT"
echo "Created Review Draft at $REVIEW_DRAFT"
header "Please verify that only one line changed relative to $INPUT_FILE:"
diff -up "$INPUT_FILE" "$REVIEW_DRAFT" || true

git add review-drafts/*
git commit -m "Review Draft Publication: $(date +'%B %G')"
