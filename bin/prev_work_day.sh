#!/bin/bash

IN_DATE=$1

if [ "$IN_DATE" == "" ]; then
    IN_DATE=`date +%Y%m%d`
fi

DAY=$(date "--date=${IN_DATE}" +%a)

if [ "${DAY}" == "Mon" ]; then
    RTN_DATE=$(date "--date=${IN_DATE} - 3 days" +%Y%m%d)
else
    RTN_DATE=$(date "--date=${IN_DATE} - 1 days" +%Y%m%d)
fi

# Check if RTN_DATE is a Holiday.  If it is, go back another day.

if [ ! -f /etc/holidays ]; then
  echo "Can't validate Holidays"
  echo "Missing Holidays source file: /etc/holidays"
  exit -1
fi

if grep -q $RTN_DATE /etc/holidays; then
    DAY2=$(date "--date=${RTN_DATE}" +%a)

    if [ "${DAY2}" == "Mon" ]; then
        RTN_DATE=$(date "--date=${RTN_DATE} - 3 days" +%Y%m%d)
    else
        RTN_DATE=$(date "--date=${RTN_DATE} - 1 days" +%Y%m%d)
    fi

fi

echo $RTN_DATE