#!/bin/bash
set -e

if [[ "$TRAVIS_BRANCH" != "master" || "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    echo "Skipping deploy for a pull request"
else
    ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
    ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    openssl aes-256-cbc -K "$ENCRYPTED_KEY" -iv "$ENCRYPTED_IV" -in deploy_key.enc -out deploy_key -d
    chmod 600 deploy_key
    eval "$(ssh-agent -s)"
    ssh-add deploy_key
    echo "$SERVER $SERVER_PUBLIC_KEY" > known_hosts
    rsync --archive --chmod="D755,F644" --verbose --compress --delete --rsh="ssh -o UserKnownHostsFile=known_hosts" ./whatwg.org ./*.whatwg.org "deploy@$SERVER:/var/www/"
fi
