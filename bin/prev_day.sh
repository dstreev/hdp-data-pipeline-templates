#!/bin/bash

IN_DATE=$1

DAY=$(date "--date=${IN_DATE}" +%a)

RTN_DATE=$(date "--date=${IN_DATE} - 1 days" +%Y%m%d)

echo $RTN_DATE