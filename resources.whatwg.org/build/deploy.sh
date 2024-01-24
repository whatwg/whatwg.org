#!/bin/bash
set -o errexit
set -o nounset

# This script is maintained at
# https://github.com/whatwg/whatwg.org/tree/main/resources.whatwg.org/build.
# See README.md for documentation.

# This extracts the repository name from the remote URL, as the component after the final slash,
# stripping any trailing .git, to be robust against various remote URLs locally and in CI.
SHORTNAME=$(git config --local remote.origin.url | sed 's/.*\///' | sed 's/.git//')
INPUT_FILE=$(find . -maxdepth 1 -name "*.bs" -print -quit)

WEB_ROOT="$SHORTNAME.spec.whatwg.org"
COMMITS_DIR="commit-snapshots"
REVIEW_DRAFTS_DIR="review-drafts"

# Optional environment variables (won't be set for local deploys)
GITHUB_ACTIONS=${GITHUB_ACTIONS:-false}
GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME:-}
GITHUB_REF=${GITHUB_REF:-}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}
SERVER=${SERVER:-}
SERVER_PUBLIC_KEY=${SERVER_PUBLIC_KEY:-}
SERVER_DEPLOY_KEY=${SERVER_DEPLOY_KEY:-}
EXTRA_FILES=${EXTRA_FILES:-}
POST_BUILD_STEP=${POST_BUILD_STEP:-}

if [[ "$GITHUB_ACTIONS" != "true" ]]; then
    echo "Running a local deploy into $WEB_ROOT directory"
fi

SHA=$(git rev-parse HEAD)

echo ""
echo "Running deploy for commit: $SHA"
echo ""

rm -rf "$WEB_ROOT" || exit 0

copy_extra_files() {
    if [[ "$EXTRA_FILES" != "" ]]; then
        echo "Copying extra files ($EXTRA_FILES) to $1"
        # Will not pass shellcheck: https://stackoverflow.com/q/45931553/3191
        # shellcheck disable=SC2086
        rsync --relative $EXTRA_FILES "$1"
    fi
}

run_post_build_step() {
    if [[ "$POST_BUILD_STEP" != "" ]]; then
        echo "Running post build step ($POST_BUILD_STEP) for $1"
        DIR="$1" bash -c "$POST_BUILD_STEP"
    fi
}

header() {
    echo -e "\\x1b[1m$1\\x1b[0m"
}

curlretry() {
    curl --retry 2 "$@"
}

header "Linting the source:"
MATCHES=$(
  perl -ne '$/ = "\n\n"; print "$_" if (/chosing|approprate|occured|elemenst|\bteh\b|\blabelled\b|\blabelling\b|\bhte\b|taht|linx\b|speciication|attribue|kestern|horiontal|\battribute\s+attribute\b|\bthe\s+the\b|\bthe\s+there\b|\bfor\s+for\b|\bor\s+or\b|\bany\s+any\b|\bbe\s+be\b|\bwith\s+with\b|\bis\s+is\b/si)' "$INPUT_FILE" | perl -lpe 'print "\nPossible typos:" if $. == 1'
  grep -niE '((anonym|author|categor|custom|emphas|initial|local|minim|neutral|normal|optim|raster|real|recogn|roman|serial|standard|summar|synchron|synthes|token|optim)is(e|ing|ation|ability)|(col|behavi|hono|fav)our)' "$INPUT_FILE" | grep -vE '\ben-GB\b' | perl -lpe 'print "\nen-GB spelling (use lang=\"en-GB\", or <!-- en-GB -->, on the same line to override):" if $. == 1'
  perl -ne '$/ = "\n\n"; print "$_" if (/\ban\s+(<[^>]*>)*(?!(L\b|LL|http|https|href|hgroup|rb|rp|rt|rtc|li|xml|svg|svgmatrix|hour|hr|xhtml|xslt|xbl|nntp|mpeg|mp3|m[ions]|mtext|merror|h[1-6]|xmlns|xpath|s|x|sgml|huang|srgb|rgba?|rsa|rst_stream|only|option|optgroup)\b|html)[b-df-hj-np-tv-z]/si or /\b(?<![<\/;])a\s+(?!<!--grammar-check-override-->|eklund)(<[^>]*>)*(?!&gt|one)(?:(L\b|http|https|href|hgroup|rt|rp|li|xml|svg|svgmatrix|hour|hr|xhtml|xslt|xbl|nntp|mpeg|mp3|m[ions]|mtext|merror|h[1-6]|xmlns|xpath|s|x|sgml|huang|srgb|rgba?|rsa|only|option|optgroup)\b|html|[aeio])/si)' "$INPUT_FILE" | perl -lpe 'print "\nPossible grammar problem: \"a\" instead of \"an\" or vice versa (to override, use e.g. \"a <!--grammar-check-override-->apple\"):" if $. == 1'
  grep -ni 'and/or' "$INPUT_FILE" | perl -lpe 'print "\nOccurrences of making Ms2ger unhappy and/or annoyed:" if $. == 1'
  grep -niE '\s+$' "$INPUT_FILE" | perl -lpe 'print "\nTrailing whitespace:" if $. == 1'
  grep $'\t' "$INPUT_FILE" | perl -lpe 'print "\nTab:" if $. == 1'
  grep $'\xc2\xa0' "$INPUT_FILE" | perl -lpe 'print "\nUnescaped nonbreaking space:" if $. == 1'
  grep $'[\u226a\u226b]' "$INPUT_FILE" | perl -lpe 'print "\nWrong list literals, use \uAB\uBB instead:" if $. == 1'
)
if [ -n "$MATCHES" ]; then
  echo "$MATCHES"
  exit 1
else
  echo "All good"
fi
echo ""

header "Starting commit snapshot..."
COMMIT_DIR="$WEB_ROOT/$COMMITS_DIR/$SHA"
mkdir -p "$COMMIT_DIR"
bikeshed spec "$INPUT_FILE" \
              "$COMMIT_DIR/index.html" \
              --md-status=LS-COMMIT \
              --md-Text-Macro="COMMIT-SHA $SHA"
copy_extra_files "$COMMIT_DIR"
run_post_build_step "$COMMIT_DIR"
echo "Commit snapshot output to $COMMIT_DIR"
echo ""

header "Starting living standard..."
bikeshed spec "$INPUT_FILE" \
              "$WEB_ROOT/index.html" \
              --md-Text-Macro="COMMIT-SHA $SHA"
copy_extra_files "$WEB_ROOT"
run_post_build_step "$WEB_ROOT"
echo "Living standard output to $WEB_ROOT"
echo ""

header "Starting review drafts (if applicable)..."
echo "Note: review drafts must be added or changed in a single commit on main"
CHANGED_FILES=$(git show --format="format:" --name-only HEAD)
for CHANGED in $CHANGED_FILES; do # Omit quotes around variable to split on whitespace
    if ! [[ "$CHANGED" =~ ^review-drafts/.*.bs$ ]]; then
        continue
    fi
    echo ""
    BASENAME=$(basename "$CHANGED" .bs)
    DRAFT_DIR="$WEB_ROOT/$REVIEW_DRAFTS_DIR/$BASENAME"
    mkdir -p "$DRAFT_DIR"
    bikeshed spec "$CHANGED" \
                  "$DRAFT_DIR/index.html"
    copy_extra_files "$DRAFT_DIR"
    run_post_build_step "$DRAFT_DIR"
    echo "Review draft output to $DRAFT_DIR"
done
echo ""

# Standard service worker and robots.txt
header "Getting the service worker hash..."
SERVICE_WORKER_SHA=$(curlretry --fail https://resources.whatwg.org/standard-service-worker.js | shasum | cut -c 1-40)

EXTRA_FILES_JS=""
if [[ "$EXTRA_FILES" != "" ]]; then
    # Will not pass shellcheck: https://stackoverflow.com/q/45931553/3191
    # shellcheck disable=SC2206
    EXTRA_FILES_ARR=($EXTRA_FILES)
    EXTRA_FILES_JS="
self.extraFiles = [
$(printf '  "/%s",\n' "${EXTRA_FILES_ARR[@]}")
];
"
fi
echo "\"use strict\";
$EXTRA_FILES_JS
importScripts(\"https://resources.whatwg.org/standard-service-worker.js\");
// Version (for service worker freshness check): $SERVICE_WORKER_SHA" \
     > "$WEB_ROOT/service-worker.js"
echo "User-agent: *
Disallow: /branch-snapshots/
Disallow: /commit-snapshots/
Disallow: /review-drafts/" > "$WEB_ROOT/robots.txt"
echo "Service worker and robots.txt output to $WEB_ROOT"
echo ""

header "Overview of generated files:"
find "$WEB_ROOT" -type f -print
echo ""

# Run the HTML checker only in CI
if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    header "Running the HTML checker..."
    curlretry --fail --remote-name --location https://github.com/validator/validator/releases/download/latest/vnu.linux.zip
    unzip -q vnu.linux.zip
    if [ -f .htmlcheckerfilter ]; then
      ./vnu-runtime-image/bin/vnu --verbose --skip-non-html --Werror --filterfile .htmlcheckerfilter "$WEB_ROOT"
    else
      ./vnu-runtime-image/bin/vnu --verbose --skip-non-html --Werror "$WEB_ROOT"
    fi
    echo ""
fi

# Deploy from push to main branch on non-forks only
if [[ "$GITHUB_REPOSITORY" == whatwg/* && "$GITHUB_EVENT_NAME" == "push" && "$GITHUB_REF" == "refs/heads/main" ]]; then
    header "rsync to the WHATWG server..."
    eval "$(ssh-agent -s)"
    echo "$SERVER_DEPLOY_KEY" | ssh-add -
    mkdir -p ~/.ssh/ && echo "$SERVER $SERVER_PUBLIC_KEY" > ~/.ssh/known_hosts
    # No --delete as that would require extra care to not delete snapshots.
    # --chmod=D755,F644 means read-write for user, read-only for others.
    rsync --verbose --archive --chmod=D755,F644 --compress \
          "$WEB_ROOT" "deploy@$SERVER:/var/www/"
else
    header "Skipping deploy"
fi
