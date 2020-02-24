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

echo "Copying browser logos"
copy_logo() {
    declare source_file="node_modules/@browser-logos/$1"
    declare target_file="resources.whatwg.org/browser-logos/$2"

    echo "  $source_file => $target_file"
    cp "$source_file" "$target_file"
}
copy_logo "android-webview-beta/android-webview-beta_32x32.png" "android-webview.png"
copy_logo "chrome/chrome.svg" "chrome.svg"
copy_logo "edge/edge.svg" "edge.svg"
copy_logo "edge_12-18/edge_12-18.svg" "edge_legacy.svg"
copy_logo "firefox/firefox_32x32.png" "firefox.png"
copy_logo "internet-explorer-tile_10-11/internet-explorer-tile_10-11.svg" "ie-mobile.svg"
copy_logo "internet-explorer_9-11/internet-explorer_9-11_32x32.png" "ie.png"
copy_logo "opera-mini/opera-mini_32x32.png" "opera-mini.png"
copy_logo "opera/opera.svg" "opera.svg"
copy_logo "safari-ios/safari-ios.svg" "safari-ios.svg"
copy_logo "safari/safari_32x32.png" "safari.png"
copy_logo "samsung-internet/samsung-internet.svg" "samsung.svg"
copy_logo "uc/uc_32x32.png" "uc.png"
echo "Browser logos copied"
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
    # --itemize-changes is used instead of --verbose because the total number of
    # files is too large to list without exceeding Travis log size limits.
    rsync --archive --chmod="D755,F644" --itemize-changes --compress --delete --rsh="ssh -o UserKnownHostsFile=known_hosts" ./whatwg.org ./*.whatwg.org "deploy@$SERVER:/var/www/"
fi
