#!/usr/bin/env bash
#
# Find the last BUSINESS Day of the Month in 'd' format
#
# Use this to compare against the current Day Of the Month to see if this is the LAST Business Day of the Month.
#
# For example, you want to run a script on the last business day of the month.
# For a specific day
# [ `./lbdom.sh 2015-05-29` == true ] && echo Hello
# Or for the current day
# [ `./lbdom.sh` == true ] && echo Hello
#

SourceDate=$1

if [ "$SourceDate" == "" ]; then
        SourceDate=$(date +%Y-%m-01)
        SourceDay=$(date +%d)
else
        SourceDay=$(date --date $SourceDate +%d)
        SourceDate=$(date --date $SourceDate +%Y-%m-01)
fi

#echo "Source Date: " $SourceDate

EndOfMonthDay=$(date -d "$SourceDate +1 month -1 day" +%d)
EndOfMonthDayOfWeek=$(date -d "$SourceDate +1 month -1 day" +%u)

#echo $EndOfMonthDay
#echo $EndOfMonthDayOfWeek

if [[ $EndOfMonthDayOfWeek = 6 || $EndOfMonthDayOfWeek = 7 ]]; then
        (( Offset = 5 - $EndOfMonthDayOfWeek ))    # then make it Fri
        LastBusinessDay=$(date -d "$SourceDate $Offset day" +%d)
else
        LastBusinessDay=$EndOfMonthDay
fi
#echo $LastBusinessDay $SourceDay
if [ $LastBusinessDay -eq $SourceDay ]; then
        echo -n true
else
        echo -n false
fi
