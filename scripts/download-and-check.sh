#!/bin/bash

set +m

list="$1"

url=""
while IFS= read -r line; do
    case "$line" in
        "Download: "*)
            url="${line#Download: }"
            ;;
        "MD5 sum: "*)
            md5="${line#MD5 sum: }"

            file=$(basename "$url")

            wget -c "$url"

            echo "$md5  $file" | md5sum -c - || exit 1
            ;;
    esac
done < "$list"
