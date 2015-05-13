#!/bin/bash

if [ ! -f ${HOME}/.bee-env.sh ]; then
    echo "Missing HOME/.bee-env.sh script"
    exit -1
fi

. ${HOME}/.bee-env.sh

beeline -u $URL -n $USER "$@"