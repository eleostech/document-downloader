#!/bin/bash

set -e

VERSION=$(git tag --points-at HEAD | sed -e 's/^v//')

if [ -z "$VERSION" ]; then
    echo "The current HEAD is not tagged. You must tag before cutting a release."
    exit 1
fi

zip document-downloader-$VERSION.zip configurations.json *.ps1 README.txt
