#!/bin/bash

set -e

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <download-list>" >&2
    exit 1
fi

LIST="$1"
DEST="$LFS/sources"

download_file() {
    local url="$1"
    local expected_md5="$2"
    local filename="${url##*/}"

    if [[ -f "$DEST/$filename" ]]; then
        if echo "$expected_md5  $DEST/$filename" | md5sum -c --status; then
            echo "SKIP: $filename (MD5 OK)"
            return 0
        fi
        echo "MD5 mismatch: $filename"
    fi

    echo "DOWNLOAD: $filename"
    wget --read-timeout=30 \
         --connect-timeout=5 \
         --dns-timeout=5 \
         --tries=3 \
         -O "$DEST/${filename}.tmp" "$url"

    if ! echo "$expected_md5  $DEST/${filename}.tmp" | md5sum -c --status; then
        echo "ERROR: MD5 mismatch after download: $filename" >&2
        rm -f "$DEST/${filename}.tmp"
        return 1
    fi

    mv -f "$DEST/${filename}.tmp" "$DEST/$filename"
    echo "OK: $filename"
}

url=""

while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
        "Download: "*)
            url="${line#Download: }"
            ;;
        "MD5 sum: "*)
            if [[ -z "$url" ]]; then
                echo "ERROR: MD5 sum without Download URL" >&2
                exit 1
            fi

            md5="${line#MD5 sum: }"
            download_file "$url" "$md5"
            url=""
            ;;
    esac
done < "$LIST"

