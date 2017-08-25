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
    echo "$NEW_SERVER $NEW_SERVER_PUBLIC_KEY" >> known_hosts
    # TODO: remove this copy when the old server is gone
    cp spec.whatwg.org/index.html whatwg.org/specs/index
    rsync --archive --verbose --compress --delete --rsh="ssh -o UserKnownHostsFile=known_hosts" whatwg.org/ $DEPLOY_USER@$SERVER:whatwg.org/
    rsync --archive --chmod=D755,F644 --verbose --compress --delete --rsh="ssh -o UserKnownHostsFile=known_hosts" whatwg.org *.whatwg.org deploy@$NEW_SERVER:/var/www/
fi
