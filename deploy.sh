#!/bin/bash
set -e

header() {
    echo -e "\\x1b[1m$1\\x1b[0m"
}

header "Importing content from whatwg/sg and making it suitable for whatwg.org"
git clone --depth=1 https://github.com/whatwg/sg sg
./convert_policy.py
./convert_sg_db.py
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

# Run the HTML checker only when building on CI
if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    header "Running the HTML checker..."

    # Check most of the extensionless files in whatwg.org/, plus targets explicitly listed.
    readarray -d '' TARGETS < <(find whatwg.org -maxdepth 1 -type f ! -name "*.*" ! -name "status-2008-12" -print0)
    TARGETS+=(whatwg.org/news whatwg.org/validator whatwg.org/index.html idea.whatwg.org/index.html spec.whatwg.org/index.html)

    curl --retry 2 --fail --remote-name --location https://github.com/validator/validator/releases/download/linux/vnu.linux.zip
    unzip -qq vnu.linux.zip
    ./vnu-runtime-image/bin/vnu --Werror "${TARGETS[@]}"
    echo ""
fi

# This ensures that only changes to the master branch get deployed
if [[ "$GITHUB_EVENT_NAME" == "push" && "$GITHUB_REF" == "refs/heads/master" ]]; then
    header "Synchronizing content with whatwg.org et al"
    eval "$(ssh-agent -s)"
    echo "$SERVER_DEPLOY_KEY" | ssh-add -
    mkdir -p ~/.ssh/ && echo "$SERVER $SERVER_PUBLIC_KEY" > ~/.ssh/known_hosts
    rsync --verbose --archive --chmod=D755,F644 --compress --delete \
          ./whatwg.org ./*.whatwg.org "deploy@$SERVER:/var/www/"
else
    header "Skipping deploy"
fi
