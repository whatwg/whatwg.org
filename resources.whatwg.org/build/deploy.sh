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
BRANCH_URL_BASE="https://github.com/whatwg/$SHORTNAME/tree/"
WEB_ROOT="$SHORTNAME.spec.whatwg.org"
COMMITS_DIR="commit-snapshots"
BRANCHES_DIR="branch-snapshots"

SERVER="75.119.197.251"
SERVER_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDP7zWfhJdjre9BHhfOtN52v6kIaDM/1kEJV4HqinvLP2hzworwNBmTtAlIMS2JJzSiE+9WcvSbSqmw7FKmNVGtvCd/CNJJkdAOEzYFBntYLf4cwNozCRmRI0O0awTaekIm03pzLO+iJm0+xmdCjIJNDW1v8B7SwXR9t4ElYNfhYD4HAT+aP+qs6CquBbOPfVdPgQMar6iDocAOQuBFBaUHJxPGMAG0qkVRJSwS4gi8VIXNbFrLCCXnwDC4REN05J7q7w90/8/Xjt0q+im2sBUxoXcHAl38ZkHeFJry/He2CiCc8YPoOAWmM8Vd0Ukc4SYZ99UfW/bxDroLHobLQ9Eh"
NEW_SERVER="165.227.248.76"
NEW_SERVER_PUBLIC_KEY="ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDt6Igtp73aTOYXuFb8qLtgs80wWF6cNi3/AItpWAMpX3PymUw7stU7Pi+IoBJz21nfgmxaKp3gfSe2DPNt06l8="

# Optional environment variables (won't be set for local deploys)
TRAVIS=${TRAVIS:-false}
TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST:-false}
DEPLOY_USER=${DEPLOY_USER:-}
EXTRA_FILES=${EXTRA_FILES:-}

# Note: $TRAVIS_PULL_REQUEST is either a number or false, not true or false.
# https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
if [[ "$TRAVIS" == "true" && "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    echo "Skipping deploy for a pull request; the branch build will suffice"
    exit 0
fi

if [[ "$TRAVIS" == "true" && "$DEPLOY_USER" == "" ]]; then
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
        # spellcheck disable=extrafiles
        cp $EXTRA_FILES "$1"
    fi
}

if [[ $BRANCH != "master" ]] ; then
    # Branch snapshot, if not master
    BRANCH_DIR="$WEB_ROOT/$BRANCHES_DIR/$BRANCH"
    mkdir -p "$BRANCH_DIR"
    curl https://api.csswg.org/bikeshed/ -f -F file=@"$INPUT_FILE" -F md-status=LS-BRANCH \
         -F md-warning="Branch $BRANCH $BRANCH_URL_BASE$BRANCH replaced by $LS_URL" \
         -F md-title="$TITLE (Branch Snapshot $BRANCH)" \
         -F md-Text-Macro="SNAPSHOT-LINK $BACK_TO_LS_LINK" \
         > "$BRANCH_DIR/index.html";
    copy_extra_files "$BRANCH_DIR"
    echo "Branch snapshot output to $BRANCH_DIR"
else
    # Commit snapshot, if master
    COMMIT_DIR="$WEB_ROOT/$COMMITS_DIR/$SHA"
    mkdir -p "$COMMIT_DIR"
    curl https://api.csswg.org/bikeshed/ -f -F file=@"$INPUT_FILE" -F md-status=LS-COMMIT \
         -F md-warning="Commit $SHA $COMMIT_URL_BASE$SHA replaced by $LS_URL" \
         -F md-title="$TITLE (Commit Snapshot $SHA)" \
         -F md-Text-Macro="SNAPSHOT-LINK $BACK_TO_LS_LINK" \
         > "$COMMIT_DIR/index.html";
    copy_extra_files "$COMMIT_DIR"
    echo "Commit snapshot output to $COMMIT_DIR"
    echo ""

    # Living standard, if master
    curl https://api.csswg.org/bikeshed/ -f -F file=@"$INPUT_FILE" \
         -F md-Text-Macro="SNAPSHOT-LINK $SNAPSHOT_LINK" \
         > "$WEB_ROOT/index.html"
    copy_extra_files "$WEB_ROOT"

    SERVICE_WORKER_SHA=$(curl --fail https://resources.whatwg.org/standard-service-worker.js | shasum | cut -c 1-40)
    echo "\"use strict\";
importScripts(\"https://resources.whatwg.org/standard-service-worker.js\");
// Version (for service worker freshness check): $SERVICE_WORKER_SHA" \
       > "$WEB_ROOT/service-worker.js"

    echo "Living standard output to $WEB_ROOT"
fi

echo ""
find "$WEB_ROOT" -type f -print
echo ""

if [[ "$TRAVIS" == "true" ]]; then
    # Run the HTML checker only when building on Travis
    curl -O https://sideshowbarker.net/nightlies/jar/vnu.jar
    /usr/lib/jvm/java-8-oracle/jre/bin/java -jar vnu.jar --skip-non-html "$WEB_ROOT"

    # Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
    ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
    ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    openssl aes-256-cbc -K "$ENCRYPTED_KEY" -iv "$ENCRYPTED_IV" -in deploy_key.enc -out deploy_key -d
    chmod 600 deploy_key
    eval "$(ssh-agent -s)"
    ssh-add deploy_key

    # scp to the WHATWG server
    echo "$SERVER $SERVER_PUBLIC_KEY" > known_hosts
    scp -r -o UserKnownHostsFile=known_hosts "$WEB_ROOT" "$DEPLOY_USER@$SERVER":

    # rsync to the new WHATWG server. No --delete as that would require extra
    # care to not delete snapshots.
    echo "$NEW_SERVER $NEW_SERVER_PUBLIC_KEY" > known_hosts
    rsync --rsh="ssh -o UserKnownHostsFile=known_hosts" --verbose \
          --archive --chmod=D755,F644 --compress \
          "$WEB_ROOT" deploy@$NEW_SERVER:/var/www/
fi
