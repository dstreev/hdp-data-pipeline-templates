#!/bin/bash

# Run a HSQL Script and email results.

while [ $# -gt 0 ]; do
  case "$1" in
    --to)
      shift
      to=$1
      shift
      ;;
    --subject)
      shift
      subject=$1
      shift
      ;;
    --body)
      shift
      body=$1
      shift
      ;;
    --from)
      shift
      from=$1
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

attachment=`mktemp`

#echo "Subject: ${SUBJECT} for ${DT}" > $TEMP_FILE
#echo "from: ${FROM}" >> $TEMP_FILE
#echo "to: ${EMAIL}" >> $TEMP_FILE

${BEEWRAP_SCRIPT} --hivevar reporting_dt=${DT} --outputformat=dsv --nullemptystring=true --delimiterForDSV=, --silent-true -f ${SQL_FILE} | grep -v "^$" >> ${attachment}



#from="sender@example.com"
#to="recipient@example.org"
#subject="Some fancy title"
boundary="ZZ_/afg6432dfgkl.94531q"
#body="This is the body of our email"
declare -a attachments
attachments=( ${attachment} )

# Build headers
{

printf '%s\n' "From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"

--${boundary}
Content-Type: text/plain; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

$body
"

# now loop over the attachments, guess the type
# and produce the corresponding part, encoded base64
for file in "${attachments[@]}"; do

  [ ! -f "$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue

  mimetype=$(get_mimetype "$file")

  printf '%s\n' "--${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$file\"
"

  base64 "$file"
  echo
done

# print last boundary with closing --
printf '%s\n' "--${boundary}--"

} | sendmail -t -oi   # one may also use -f here to set the envelope-from

#sleep 5

#/usr/sbin/sendmail -t < $TEMP_FILE

