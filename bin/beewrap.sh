#!/bin/bash

if [ ! -f ${HOME}/.bee-env.sh ]; then
    echo "Missing HOME/.bee-env.sh script"
    exit -1
fi

. ${HOME}/.bee-env.sh

echo "Beeline Call: beeline -u $URL -$USER ${@}"

beeline -u $URL -n $USER "$@"