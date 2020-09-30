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

git checkout master
git pull
git checkout -b "review-draft-$(date +'%F')"
echo ""

INPUT=$(find . -maxdepth 1 -name "*.bs" -print -quit)
YYYYMM="$(date +'%Y-%m')"

sed -E -i '' 's/Text Macro: LATESTRD '[0-9]\+'-'[0-9]\+'/Text Macro: LATESTRD '"$YYYYMM"'/' "$INPUT"
echo "Updated Living Standard to point to the new Review Draft"
header "Please verify that only one line changed:"
git diff -up
echo ""

mkdir -p "review-drafts"
REVIEW_DRAFT="review-drafts/$YYYYMM.bs"

# The backslash+linefeed literal is for sed.
# shellcheck disable=SC1004
sed 's/^Group: WHATWG$/&\
'"Date: $(date +'%Y-%m-%d')/g" < "$INPUT" > "$REVIEW_DRAFT"
echo "Created Review Draft at $REVIEW_DRAFT"
header "Please verify that only one line changed relative to $INPUT:"
diff -up "$INPUT" "$REVIEW_DRAFT" || true

git add "$INPUT"
git add review-drafts/*
git commit -m "Review Draft Publication: $(date +'%B %G')"
