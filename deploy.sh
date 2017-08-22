#!/bin/bash
set -e

if [ "$TRAVIS_BRANCH" != "master" -o "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo "Skipping deploy for a pull request"
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
    echo "$IDEA_SERVER $IDEA_SERVER_PUBLIC_KEY" > known_hosts
    rsync --archive --verbose --compress --delete --rsh="ssh -o UserKnownHostsFile=known_hosts" src/ $DEPLOY_USER@$SERVER:$WEB_ROOT/
    rsync --archive --verbose --compress --delete --rsh="ssh -o UserKnownHostsFile=known_hosts" idea.whatwg.org/ admini@$IDEA_SERVER:$IDEA_WEB_ROOT/
fi
