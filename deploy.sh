#!/bin/bash
set -e

header() {
    echo -e "\\x1b[1m$1\\x1b[0m"
}

header "Importing content from whatwg/sg and making it suitable for whatwg.org"
git clone --depth=1 https://github.com/whatwg/sg sg
./convert-policy.py
mv sg/working-mode whatwg.org/working-mode
rm -rf sg
echo ""

header "Creating snapshot logos"
for LOGO in resources.whatwg.org/logo*.svg; do
    BASENAME=$(basename "$LOGO" .svg)
    sed s/#3c790a/#666/g < "$LOGO" > "resources.whatwg.org/$BASENAME-snapshot.svg"
done
echo ""

header "Copying browser logos"
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
echo ""

# Run the HTML checker only when building on Travis
if [[ "$TRAVIS" == "true" ]]; then
    header "Running the HTML checker..."

    # Check the targets given explicitly here, plus most of the extensionless files directly inside
    # whatwg.org/. This uses https://stackoverflow.com/a/23357277/3191 to get the results of the
    # find command into an array. TODO: if Travis CI ever gets Bash 4.4, we can use the simpler
    # version at https://stackoverflow.com/a/54561526/3191.
    TARGETS=(whatwg.org/news whatwg.org/validator whatwg.org/index.html idea.whatwg.org/index.html spec.whatwg.org/index.html)
    while IFS=  read -r -d $'\0'; do
        TARGETS+=("$REPLY")
    done < <(find whatwg.org -maxdepth 1 -type f ! -name "*.*" ! -name "status-2008-12" -print0)

    curl --retry 2 --fail --remote-name --location https://github.com/validator/validator/releases/download/jar/vnu.jar
    /usr/lib/jvm/java-8-oracle/jre/bin/java -jar vnu.jar --Werror "${TARGETS[@]}"
    echo ""
fi

# This ensures that only changes to the master branch get deployed
if [[ "$TRAVIS_BRANCH" != "master" || "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    header "Skipping deploy"
else
    header "Synchronizing content with whatwg.org et al"
    ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
    ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
    ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
    ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
    openssl aes-256-cbc -K "$ENCRYPTED_KEY" -iv "$ENCRYPTED_IV" -in deploy_key.enc -out deploy_key -d
    chmod 600 deploy_key
    eval "$(ssh-agent -s)"
    ssh-add deploy_key
    echo "$SERVER $SERVER_PUBLIC_KEY" > known_hosts
    # --verbose isn't used because there are too many files to list them all
    # without exceeding log size limits:
    # https://github.com/whatwg/whatwg.org/issues/287
    rsync --archive --chmod="D755,F644" --compress --delete --stats --log-file="rsync-log.txt" --rsh="ssh -o UserKnownHostsFile=known_hosts" ./whatwg.org ./*.whatwg.org "deploy@$SERVER:/var/www/"
    scp -o="UserKnownHostsFile=known_hosts" rsync-log.txt "deploy@$SERVER:/var/www/whatwg.org/"
    echo "Full rsync log at https://whatwg.org/rsync-log.txt"
fi
