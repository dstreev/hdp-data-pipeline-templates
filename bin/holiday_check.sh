#!/usr/bin/env bash

if [ ! -f /etc/holidays ]; then
  echo "Can't validate Holidays"
  echo "Missing Holidays source file: /etc/holidays"
  exit -1
fi

TODAY=$(date +%Y%m%d)

if grep -q $TODAY /etc/holidays; then
   echo Skipping holiday for $*
   exit 0
fi

$*