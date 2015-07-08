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

echo $RTN_DATE