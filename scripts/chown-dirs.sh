#!/bin/bash

: "${LFS:?LFS environment variable is not set}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <username>" >&2
    exit 1
fi
USERNAME=$1

chown -v $USERNAME $LFS/{usr{,/*},var,etc,tools}

case $(uname -m) in
  x86_64) chown -v $USERNAME $LFS/lib64 ;;
esac
