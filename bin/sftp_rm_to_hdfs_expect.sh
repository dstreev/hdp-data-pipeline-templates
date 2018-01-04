#!/bin/bash

#######
# Get file from an SFTP site using an 'expect' script and put it on HDFS.
#
# Works on SINGLE Files, no Wildcards.
#
# Feed file format:
#   SFTP_SOURCE_DIR FILE_PREFIX HDFS_TARGET_DIR
#   /Data/Outbound/Curves USD_TREASURY.csv /user/wre/wrelib/curves
#######

DATE_WITHOUT_DASHES=false
YESTERDAY=false
NO_SRC_DATE=false
APPEND_DATE_TO_TARGET=false
DELETE_SRC=false


while [ $# -gt 0 ]; do
  case "$1" in
    --ssh_env)
      shift
      SSH_ENV=$1
      shift
      ;;
    --feed_file)
      shift
      FEED_FILE=$1
      shift
      ;;
    --no_src_date)
      NO_SRC_DATE=true
      shift
      ;;
    --append_date_to_target)
      APPEND_DATE_TO_TARGET=true
      shift
      ;;
    --delete_src)
      DELETE_SRC=true
      shift
      ;;
    --date)
      shift
      DT=$1
      shift
      ;;
    --yesterday)
      shift
      YESTERDAY=true
      ;;
    --expect)
      shift
      EXPECT_SCRIPT=$1
      shift
      ;;
    --date_without_dashes)
        shift
        DATE_WITHOUT_DASHES=true
        ;;
    --check)
      CHECK="yes"
      shift
      ;;
    --help)
      echo "Usage: $0 --date <date in yyyyMMdd> --help"
      exit -1
      ;;
    *)
      break
      ;;
  esac
done

if [ "$DT" == "" ]; then
    DT=`date +%Y%m%d`
fi

if [ "${YESTERDAY}" == "true" ]; then
    DT=`./prev_work_day.sh ${DT}`
fi

if [ -f ${SSH_ENV} ]; then
    . ${SSH_ENV}
else
    echo "Can't locate environment file ${SSH_ENV}"
    exit -1
fi

if [ "${DATE_WITHOUT_DASHES}" == "true" ]; then
    GOOD_DT="${DT}"
else
    GOOD_DT="${DT:0:4}-${DT:4:2}-${DT:6:2}"
fi


exec< $FEED_FILE

while read line ; do
    # Create a temp directory
    BASE_OUTPUT_DIR=$( mktemp -d /tmp/transfer_XXXXXXX )

    ar=( $line )

    # Skip Comment lines
    s1=$line
    s2=#

    # Skip Commented lines
    if [ "${s1:0:${#s2}}" != "$s2" ]; then

        SRC_DIR="${ar[0]}"
        SRC_FILE="${ar[1]}"
        TARGET_DIR="${ar[2]}"

        echo "Getting  ${SRC_FILE} file from sftp"

        expect -f ${EXPECT_SCRIPT} ${SSH_PORT} ${SSH_USER} ${SSH_HOST} ${SRC_DIR} ${SRC_FILE} ${BASE_OUTPUT_DIR} ${SSH_PASSWORD}

        if [ "${APPEND_DATE_TO_TARGET}" == "false" ]; then
            TARGET_FULL_FILE="${FULL_FILE}"
        else
            TARGET_FULL_FILE="${FULL_FILE}.${GOOD_DT}"
        fi

        mv ${BASE_OUTPUT_DIR}/${SRC_FILE} ${BASE_OUTPUT_DIR}/${TARGET_FULL_FILE}

        echo "Push file ${TARGET_FULL_FILE} to HDFS Directory: ${TARGET_DIR}"
        hdfs dfs -copyFromLocal -f ${BASE_OUTPUT_DIR}/${TARGET_FULL_FILE} ${TARGET_DIR}

    fi
done

