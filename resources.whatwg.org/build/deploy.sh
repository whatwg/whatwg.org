#!/bin/bash
set -o errexit
set -o nounset

# This script is maintained at
# https://github.com/whatwg/whatwg.org/tree/master/resources.whatwg.org/build.
# See README.md for documentation.

SHORTNAME=$(git config --local remote.origin.url | sed -n 's#.*/\([^.]*\)\.git#\1#p')
INPUT_FILE=$(find . -maxdepth 1 -name "*.bs" -print -quit)
H1=$(grep < "$INPUT_FILE" "^H1: .*$" | sed -e "s/H1: //")

LS_URL="https://$SHORTNAME.spec.whatwg.org/"
COMMIT_URL_BASE="https://github.com/whatwg/$SHORTNAME/commit/"
WEB_ROOT="$SHORTNAME.spec.whatwg.org"
COMMITS_DIR="commit-snapshots"
REVIEW_DRAFTS_DIR="review-drafts"

# Optional environment variables (won't be set for local deploys)
TRAVIS=${TRAVIS:-false}
TRAVIS_BRANCH=${TRAVIS_BRANCH:-}
TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST:-false}
ENCRYPTION_LABEL=${ENCRYPTION_LABEL:-}
SERVER="165.227.248.76"
SERVER_PUBLIC_KEY="ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDt6Igtp73aTOYXuFb8qLtgs80wWF6cNi3/AItpWAMpX3PymUw7stU7Pi+IoBJz21nfgmxaKp3gfSe2DPNt06l8="
EXTRA_FILES=${EXTRA_FILES:-}
POST_BUILD_STEP=${POST_BUILD_STEP:-}

if [[ "$TRAVIS" != "true" ]]; then
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

curlbikeshed() {
    # The Accept: header ensures we get the error output even when warnings are produced, per
    # https://github.com/whatwg/whatwg.org/issues/227#issuecomment-419969339.
    HTTP_STATUS=$(curlretry https://api.csswg.org/bikeshed/ \
                            --output "$1" \
                            --write-out "%{http_code}" \
                            --header "Accept: text/plain, text/html" \
                            -F die-on=warning \
                            -F file=@"$INPUT_FILE" \
                            "${@:2}")

    if [[ "$HTTP_STATUS" != "200" ]]; then
        cat "$1"
        rm -f "$1"
        exit 22
    fi
}

header "Linting the source:"
MATCHES=$(
  perl -ne '$/ = "\n\n"; print "$_" if (/chosing|approprate|occured|elemenst|\bteh\b|\blabelled\b|\blabelling\b|\bhte\b|taht|linx\b|speciication|attribue|kestern|horiontal|\battribute\s+attribute\b|\bthe\s+the\b|\bthe\s+there\b|\bfor\s+for\b|\bor\s+or\b|\bany\s+any\b|\bbe\s+be\b|\bwith\s+with\b|\bis\s+is\b/si)' "$INPUT_FILE" | perl -lpe 'print "\nPossible typos:" if $. == 1'
  grep -niE '((anonym|author|categor|custom|emphas|initial|local|minim|neutral|normal|optim|raster|real|recogn|roman|serial|standard|summar|synchron|synthes|token|optim)is(e|ing|ation|ability)|(col|behavi|hono|fav)our)' "$INPUT_FILE" | grep -vE '\ben-GB\b' | perl -lpe 'print "\nen-GB spelling (use lang=\"en-GB\", or <!-- en-GB -->, on the same line to override):" if $. == 1'
  perl -ne '$/ = "\n\n"; print "$_" if (/\ban\s+(<[^>]*>)*(?!(L\b|http|https|href|hgroup|rb|rp|rt|rtc|li|xml|svg|svgmatrix|hour|hr|xhtml|xslt|xbl|nntp|mpeg|mp3|m[ions]|mtext|merror|h[1-6]|xmlns|xpath|s|x|sgml|huang|srgb|rgba?|rsa|rst_stream|only|option|optgroup)\b|html)[b-df-hj-np-tv-z]/si or /\b(?<![<\/;])a\s+(?!<!--grammar-check-override-->)(<[^>]*>)*(?!&gt|one)(?:(L\b|http|https|href|hgroup|rt|rp|li|xml|svg|svgmatrix|hour|hr|xhtml|xslt|xbl|nntp|mpeg|mp3|m[ions]|mtext|merror|h[1-6]|xmlns|xpath|s|x|sgml|huang|srgb|rgba?|rsa|only|option|optgroup)\b|html|[aeio])/si)' "$INPUT_FILE" | perl -lpe 'print "\nPossible grammar problem: \"a\" instead of \"an\" or vice versa (to override, use e.g. \"a <!--grammar-check-override-->apple\"):" if $. == 1'
  grep -ni 'and/or' "$INPUT_FILE" | perl -lpe 'print "\nOccurrences of making Ms2ger unhappy and/or annoyed:" if $. == 1'
  grep -niE '\s+$' "$INPUT_FILE" | perl -lpe 'print "\nTrailing whitespace:" if $. == 1'
  grep $'\t' "$INPUT_FILE" | perl -lpe 'print "\nTab:" if $. == 1'
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
curlbikeshed "$COMMIT_DIR/index.html" \
             -F md-status=LS-COMMIT \
             -F md-warning="Commit $SHA $COMMIT_URL_BASE$SHA replaced by $LS_URL" \
             -F md-Text-Macro="COMMIT-SHA $SHA"
copy_extra_files "$COMMIT_DIR"
run_post_build_step "$COMMIT_DIR"
echo "Commit snapshot output to $COMMIT_DIR"
echo ""

header "Starting living standard..."
curlbikeshed "$WEB_ROOT/index.html" \
             -F md-Text-Macro="COMMIT-SHA $SHA"
copy_extra_files "$WEB_ROOT"
run_post_build_step "$WEB_ROOT"
echo "Living standard output to $WEB_ROOT"
echo ""

header "Starting review drafts (if applicable)..."
echo "Note: review drafts must be added or changed in a single commit on master"
if [[ "$TRAVIS_PULL_REQUEST" == "true" ]]; then
    CHANGED_FILES=$(git diff --name-only master..HEAD)
else
    CHANGED_FILES=$(git diff --name-only HEAD^ HEAD)
fi
for CHANGED in $CHANGED_FILES; do # Omit quotes around variable to split on whitespace
    if ! [[ "$CHANGED" =~ ^review-drafts/.*.bs$ ]]; then
        continue
    fi
    echo ""
    BASENAME=$(basename "$CHANGED" .bs)
    DRAFT_DIR="$WEB_ROOT/$REVIEW_DRAFTS_DIR/$BASENAME"
    mkdir -p "$DRAFT_DIR"
    curlbikeshed "$DRAFT_DIR/index.html" \
                 -F md-Status="RD"
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

# Run the HTML checker only when building on Travis
if [[ "$TRAVIS" == "true" ]]; then
    header "Running the HTML checker..."
    curlretry --fail --remote-name --location https://github.com/validator/validator/releases/download/linux/vnu.linux.zip
    unzip -q vnu.linux.zip
    if [ -f .htmlcheckerfilter ]; then
      ./vnu-runtime-image/bin/vnu --verbose --skip-non-html --Werror --filterfile .htmlcheckerfilter "$WEB_ROOT"
    else
      ./vnu-runtime-image/bin/vnu --verbose --skip-non-html --Werror "$WEB_ROOT"
    fi
    echo ""
fi

# Deploy from Travis on push to master branch only
if [[ "$TRAVIS_BRANCH" == "master" && "$TRAVIS_PULL_REQUEST" == "false" ]]; then
    header "rsync to the WHATWG server..."
    # Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
    ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
    ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    openssl aes-256-cbc -K "$ENCRYPTED_KEY" -iv "$ENCRYPTED_IV" -in deploy_key.enc -out deploy_key -d
    chmod 600 deploy_key
    eval "$(ssh-agent -s)"
    ssh-add deploy_key
    echo "$SERVER $SERVER_PUBLIC_KEY" > known_hosts
    # No --delete as that would require extra care to not delete snapshots.
    # --chmod=D755,F644 means read-write for user, read-only for others.
    rsync --rsh="ssh -o UserKnownHostsFile=known_hosts" --verbose \
          --archive --chmod=D755,F644 --compress \
          "$WEB_ROOT" deploy@$SERVER:/var/www/
    echo ""
fi
