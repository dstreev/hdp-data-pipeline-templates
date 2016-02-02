#!/bin/bash

# Run a HSQL Script and email results.

while [ $# -gt 0 ]; do
  case "$1" in
    --email)
      shift
      EMAIL=$1
      shift
      ;;
    --subject)
      shift
      SUBJECT=$1
      shift
      ;;
    --from)
      shift
      FROM=$1
      shift
      ;;
    --date)
      shift
      DT=$1
      shift
      ;;
    --sql_file)
      shift
      SQL_FILE=$1
      shift
      ;;
    --beewrap_script)
      shift
      BEEWRAP_SCRIPT=$1
      shift
      ;;
    --help)
      echo "Usage: $0 --date <date in yyyy-MM-dd> --subject <subject> --sql_file <sql file> --help"
      exit -1
      ;;
    *)
      break
      ;;
  esac
done

BEEWRAP_SCRIPT=${BEEWRAP_SCRIPT:-beewrap.sh}

if [ "${DT}" == "" ]; then
    DT=`date +%Y-%m-%d`
fi

echo "Reporting Date: ${DT}"
echo "SQL File: ${SQL_FILE}"

TEMP_FILE=`mktemp`

echo "Subject: ${SUBJECT} for ${DT}" > $TEMP_FILE
echo "from: ${FROM}" >> $TEMP_FILE
echo "to: ${EMAIL}" >> $TEMP_FILE

${BEEWRAP_SCRIPT} --hivevar reporting_dt=${DT} --outputformat=dsv --nullemptystring=true --delimiterForDSV=, --silent-true -f ${SQL_FILE} | grep -v "^$" >> $TEMP_FILE

sleep 5

/usr/sbin/sendmail -t < $TEMP_FILE

