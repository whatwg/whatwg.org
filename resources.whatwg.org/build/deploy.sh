#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This script is maintained at
# https://github.com/whatwg/whatwg.org/tree/master/resources.whatwg.org/build.
# See README.md for documentation.

SHORTNAME=$(git config --local remote.origin.url | sed -n "s#.*/\([^.]*\)\.git#\1#p")
INPUT_FILE=$(find . -maxdepth 1 -name "*.bs" -print -quit)
TITLE=$(grep < "$INPUT_FILE" "^Title: .*$" | sed -e "s/Title: //")

LS_URL="https://$SHORTNAME.spec.whatwg.org/"
COMMIT_URL_BASE="https://github.com/whatwg/$SHORTNAME/commit/"
WEB_ROOT="$SHORTNAME.spec.whatwg.org"
COMMITS_DIR="commit-snapshots"

# Optional environment variables (won't be set for local deploys)
TRAVIS=${TRAVIS:-false}
TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST:-false}
ENCRYPTION_LABEL=${ENCRYPTION_LABEL:-}
SERVER="165.227.248.76"
SERVER_PUBLIC_KEY="ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDt6Igtp73aTOYXuFb8qLtgs80wWF6cNi3/AItpWAMpX3PymUw7stU7Pi+IoBJz21nfgmxaKp3gfSe2DPNt06l8="
EXTRA_FILES=${EXTRA_FILES:-}
POST_BUILD_STEP=${POST_BUILD_STEP:-}

# HTML checker filter passed to vnu.jar --filterpattern
CHECKER_FILTER=${CHECKER_FILTER:-}

# Note: $TRAVIS_PULL_REQUEST is either a number or false, not true or false.
# https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
if [[ "$TRAVIS" == "true" && "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    echo "Skipping deploy for a pull request; the branch build will suffice"
    exit 0
fi

if [[ "$TRAVIS" == "true" && "$ENCRYPTION_LABEL" == "" ]]; then
    echo "No deploy credentials present; deploy cannot continue"
    exit 1
fi

if [[ "$TRAVIS" != "true" ]]; then
    echo "Running a local deploy into $WEB_ROOT directory"
    echo ""
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$TRAVIS" == "true" ]]; then # For some reason the above does not work on Travis
    BRANCH=$TRAVIS_BRANCH
fi
SHA=$(git rev-parse HEAD)

echo "Branch = $BRANCH"
echo "Commit = $SHA"
echo ""

BACK_TO_LS_LINK="<a href=\"/\" id=\"commit-snapshot-link\">Go to the living standard</a>"
SNAPSHOT_LINK="<a href=\"/commit-snapshots/$SHA/\" id=\"commit-snapshot-link\">Snapshot as of this commit</a>"

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

if [[ "$BRANCH" == "master" ]] ; then
    # Commit snapshot, if master
    COMMIT_DIR="$WEB_ROOT/$COMMITS_DIR/$SHA"
    mkdir -p "$COMMIT_DIR"
    curl https://api.csswg.org/bikeshed/ -f -F file=@"$INPUT_FILE" -F md-status=LS-COMMIT \
         -F md-warning="Commit $SHA $COMMIT_URL_BASE$SHA replaced by $LS_URL" \
         -F md-title="$TITLE (Commit Snapshot $SHA)" \
         -F md-Text-Macro="SNAPSHOT-LINK $BACK_TO_LS_LINK" \
         > "$COMMIT_DIR/index.html";
    copy_extra_files "$COMMIT_DIR"
    run_post_build_step "$COMMIT_DIR"
    echo "Commit snapshot output to $COMMIT_DIR"
    echo ""

    # Living standard, if master
    curl https://api.csswg.org/bikeshed/ -f -F file=@"$INPUT_FILE" \
         -F md-Text-Macro="SNAPSHOT-LINK $SNAPSHOT_LINK" \
         > "$WEB_ROOT/index.html"
    copy_extra_files "$WEB_ROOT"
    run_post_build_step "$WEB_ROOT"

    SERVICE_WORKER_SHA=$(curl --fail https://resources.whatwg.org/standard-service-worker.js | shasum | cut -c 1-40)
    echo "\"use strict\";
importScripts(\"https://resources.whatwg.org/standard-service-worker.js\");
// Version (for service worker freshness check): $SERVICE_WORKER_SHA" \
       > "$WEB_ROOT/service-worker.js"

    echo "Living standard output to $WEB_ROOT"
    echo ""

    find "$WEB_ROOT" -type f -print
    echo ""
fi

if [[ "$TRAVIS" == "true" ]]; then
    # Run the HTML checker only when building on Travis
    curl -O https://sideshowbarker.net/nightlies/jar/vnu.jar
    /usr/lib/jvm/java-8-oracle/jre/bin/java -jar vnu.jar --skip-non-html --Werror --filterpattern "$CHECKER_FILTER" "$WEB_ROOT"
fi

if [[ "$TRAVIS" == "true" && "$BRANCH" == "master" ]]; then
    # Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
    ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
    ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    openssl aes-256-cbc -K "$ENCRYPTED_KEY" -iv "$ENCRYPTED_IV" -in deploy_key.enc -out deploy_key -d
    chmod 600 deploy_key
    eval "$(ssh-agent -s)"
    ssh-add deploy_key

    # rsync to the WHATWG server. No --delete as that would require extra care
    # to not delete snapshots. --chmod=D755,F644 means read-write for user,
    # read-only for others.
    echo "$SERVER $SERVER_PUBLIC_KEY" > known_hosts
    rsync --rsh="ssh -o UserKnownHostsFile=known_hosts" --verbose \
          --archive --chmod=D755,F644 --compress \
          "$WEB_ROOT" deploy@$SERVER:/var/www/
fi
