#!/bin/bash

ENV_FILE="../config/.env"
if [ -f $ENV_FILE ]; then

[ ! -f $ENV_FILE ] || export $(grep -v '^#' $ENV_FILE | xargs)

fi
