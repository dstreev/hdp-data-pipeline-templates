#!/bin/bash

#######
# Run an HSQL query and copy the results to an FTP site.
# Use a feed file to drive multiple requests.
#
# File Line Format: sqlfile<tab>target_filename<tab>remote_target_dir
#
#
#######

# Whether to add date as an extension to the output file.
DATE_EXT=true
HEADER=true
HEADER_TEMPLATE=false
PREVIOUS_DAY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --env)
      shift
      ENV=$1
      shift
      ;;
    --ftp_env)
      shift
      FTP_ENV=$1
      shift
      ;;
    --no_date_ext)
      shift
      DATE_EXT=false
      ;;
    --feed_file)
      shift
      FEED_FILE=$1
      shift
      ;;
    --header_off)
      shift
      HEADER=false
      ;;
    --header_template)
      shift
      HEADER=false
      HEADER_TEMPLATE=true
      ;;
    --date)
      shift
      DT=$1
      shift
      ;;
    --date_var)
      shift
      DATE_VAR=$1
      shift
      ;;
    --previous-workday)
      PREVIOUS_DAY=true
      shift
      ;;
    --beewrap_script)
      shift
      BEEWRAP_SCRIPT=$1
      shift
      ;;
    --check)
      CHECK="yes"
      shift
      ;;
    --help)
      echo "TODO.... Usage: $0 --date <date in yyyyMMdd> --help"
      exit -1
      ;;
    *)
      break
      ;;
  esac
done

if [ "$DT" == "" ]; then
    # Set to current date by default when not specified
    DT=`date +%Y%m%d`
fi

if [ "${PREVIOUS_DAY}" == "true" ]; then
    DAY=$(date "--date=${DT}" +%a)

    if [ "${DAY}" == "Mon" ]; then
        DT=$(date "--date=${DT} - 3 days" +%Y%m%d)
    else
        DT=$(date "--date=${DT} - 1 days" +%Y%m%d)
    fi
fi

# Set default if not specified.
BEEWRAP_SCRIPT=${BEEWRAP_SCRIPT:-beewrap.sh}
DATE_VAR=${DATE_VAR:-reporting_dt}

if [ -f ${FTP_ENV} ]; then
    . ${FTP_ENV}
else
    echo "Can't locate environment file ${FTP_ENV}"
    exit -1
fi

# Create a temp directory
BASE_OUTPUT_DIR=$( mktemp -d /tmp/HSQL_XXXXXXX )

GOOD_DT="${DT:0:4}-${DT:4:2}-${DT:6:2}"

exec< $FEED_FILE

while read line ; do
    ar=( $line )

    # Skip Comment lines
    s1=$line
    s2=#

    # Skip Commented lines
    if [ "${s1:0:${#s2}}" != "$s2" ]; then

        HSQL_SCRIPT="${ar[0]}"
#        TARGET_FILENAME="${ar[1]}"
        REMOTE_TARGET_DIR="${ar[2]}"

        if [ "${DATE_EXT}" == "true" ]; then
            TARGET_FILENAME="${ar[1]}.${DT}.csv"
        else
            TARGET_FILENAME="${ar[1]}.csv"
        fi

        echo "Processing ${HSQL_SCRIPT} - ${BASE_OUTPUT_DIR}/${TARGET_FILENAME}"

        HIVE_CMD="${BEEWRAP_SCRIPT} --hivevar ${DATE_VAR}=${GOOD_DT} --outputFormat=dsv --delimiterForDSV=';' --showHeader=${HEADER} --nullemptystring=true -f ${HSQL_SCRIPT} 2> /dev/null | grep -P -v '(^0\:\ .*)|(^\.\ \.\ .*)' > ${BASE_OUTPUT_DIR}/${TARGET_FILENAME}"

        echo "Building Export with: ${HIVE_CMD}"

        eval $HIVE_CMD

        if [ "${HEADER_TEMPLATE}" == "true" ]; then
            HEADER_TEMPLATE_FILE="${ar[3]}"
            # Create temp file
            TARGET_FILE_TMP=${TARGET_FILENAME}_new
            # Copy Template Header to Temp File
            cp -f ${HEADER_TEMPLATE_FILE} ${BASE_OUTPUT_DIR}/${TARGET_FILE_TMP}
            # Append Output File to Temp File
            cat ${BASE_OUTPUT_DIR}/${TARGET_FILENAME} >> ${BASE_OUTPUT_DIR}/${TARGET_FILE_TMP}
            # Overwrite Original with Cat'd file.
            cp -f ${BASE_OUTPUT_DIR}/${TARGET_FILE_TMP} ${BASE_OUTPUT_DIR}/${TARGET_FILENAME}
        fi

        sleep 5

        echo "Posting ${BASE_OUTPUT_DIR}/${TARGET_FILENAME} to FTP Sites directory: ${REMOTE_TARGET_DIR}"
        # Send file to FTP Site
        ftp -in <<EOF
        open $FTP_HOST
        user $FTP_USER $FTP_PASSWORD
        cd $REMOTE_TARGET_DIR
        lcd /${BASE_OUTPUT_DIR}
        put ${TARGET_FILENAME}
        quit
EOF

    fi
done

