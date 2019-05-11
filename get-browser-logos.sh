#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

copy_logo() {
    declare source_file="node_modules/@browser-logos/$1"
    declare target_file="resources.whatwg.org/browser-logos/$2"

    echo "$source_file => $target_file"
    cp "$source_file" "$target_file"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

npm install

copy_logo "android-webview-beta/android-webview-beta_32x32.png" "android-webview.png"
copy_logo "chrome/chrome.svg" "chrome.svg"
copy_logo "edge/edge.svg" "edge.svg"
copy_logo "firefox/firefox_32x32.png" "firefox.png"
copy_logo "internet-explorer-tile_10-11/internet-explorer-tile_10-11.svg" "ie-mobile.svg"
copy_logo "internet-explorer_9-11/internet-explorer_9-11_32x32.png" "ie.png"
copy_logo "opera-mini/opera-mini_32x32.png" "opera-mini.png"
copy_logo "opera/opera.svg" "opera.svg"
copy_logo "safari-ios/safari-ios.svg" "safari-ios.svg"
copy_logo "safari/safari_32x32.png" "safari.png"
copy_logo "samsung-internet/samsung-internet.svg" "samsung.svg"
copy_logo "uc/uc_32x32.png" "uc.png"
