#!/bin/bash

#######
# Get file from an FTP site and put it on HDFS.
#
# Feed file format:
#   FTP_SOURCE_DIR FILE_PREFIX HDFS_TARGET_DIR
#   /Data/Outbound/Curves USD_TREASURY_ /user/wre/wrelib/curves
#######

DATE_WITHOUT_DASHES=false
YESTERDAY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --env)
      shift
      ENV=$1
      shift
      ;;
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
    --date)
      shift
      DT=$1
      shift
      ;;
    --yesterday)
      shift
      YESTERDAY=true
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

if [ "${YESTERDAY}" == "true" ]; then
    DT=`date --date='-1 day' +%Y%m%d`
fi

if [ "$DT" == "" ]; then
    DT=`date +%Y%m%d`
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
    ar=( $line )

    # Skip Comment lines
    s1=$line
    s2=#

    # Skip Commented lines
    if [ "${s1:0:${#s2}}" != "$s2" ]; then

        SOURCE_DIR="${ar[0]}"
        PREFIX="${ar[1]}"
        TARGET_DIR="${ar[2]}"

        if [ ! -d ${TARGET_DIR} ]; then
            mkdir -p ${TARGET_DIR}
        fi

        # Fetch Files from the SCP Site.
        FULL_FILE="${PREFIX}${GOOD_DT}\*.csv"

        echo "Getting ${FULL_FILE} files from scp ${SOURCE_DIR}"

        scp -i ${SSH_KEY_FILE} -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:${SOURCE_DIR}/${FULL_FILE} ${TARGET_DIR}

    fi
done

