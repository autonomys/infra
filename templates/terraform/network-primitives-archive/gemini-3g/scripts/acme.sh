#!/bin/bash

set -e

DIRECTORY="${HOME}/subspace/letsencrypt"
if [ ! -d "$DIRECTORY" ]; then
    mkdir "$DIRECTORY"
    echo "Directory '$DIRECTORY' created."
    touch $DIRECTORY/acme.json
    chmod 600 $DIRECTORY/acme.json
    echo "ACME '$DIRECTORY/acme.json' file created."
else
    echo "Directory '$DIRECTORY' already exists."
fi
