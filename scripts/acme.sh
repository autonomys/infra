#!/bin/bash

set -e

DIRECTORY="${HOME}/subspace"
ACME_FILE="$DIRECTORY/acme.json"

# Create directory if it doesn't exist
if [ ! -d "$DIRECTORY" ]; then
    mkdir -p "$DIRECTORY"
    echo "Directory '$DIRECTORY' created."
else
    echo "Directory '$DIRECTORY' already exists."
fi

# Create ACME file if it doesn't exist
if [ ! -f "$ACME_FILE" ]; then
    touch "$ACME_FILE"
    chmod 600 "$ACME_FILE"
    echo "ACME file '$ACME_FILE' created and permissions set."
else
    echo "ACME file '$ACME_FILE' already exists."
fi
