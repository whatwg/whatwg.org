#!/bin/bash
set -e

echo "TRAVIS_BRANCH=$TRAVIS_BRANCH and TRAVIS_PULL_REQUEST=$TRAVIS_PULL_REQUEST"
echo ""

if [ "$TRAVIS_BRANCH" != "master" -o "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo "Skipping deploy for a pull request"
    exit 0
else
    ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
    ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
    chmod 600 deploy_key
    eval `ssh-agent -s`
    ssh-add deploy_key
    echo "$SERVER $SERVER_PUBLIC_KEY" > known_hosts
    rsync --archive --verbose --compress --rsh="ssh -o UserKnownHostsFile=known_hosts" src/ $DEPLOY_USER@$SERVER:$WEB_ROOT/
fi
