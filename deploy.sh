#!/bin/bash
set -e

echo "Importing content from whatwg/sg and making it suitable for whatwg.org"
git clone --depth=1 https://github.com/whatwg/sg sg
./convert-policy.py
mv sg/working-mode whatwg.org/working-mode
rm -rf sg
echo "Markdown converted to HTML"
echo ""

echo "Creating snapshot logos"
for LOGO in resources.whatwg.org/logo*.svg; do
    BASENAME=$(basename "$LOGO" .svg)
    sed s/#3c790a/#666/g < "$LOGO" > "resources.whatwg.org/$BASENAME-snapshot.svg"
done
echo "Snapshot logos created"
echo ""

# This ensures that only changes to the master branch get deployed
if [[ "$TRAVIS_BRANCH" != "master" || "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    echo "Skipping deploy"
else
    echo "Synchronizing content with whatwg.org et al"
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
