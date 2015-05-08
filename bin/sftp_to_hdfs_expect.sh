#!/bin/bash

#######
# Get file from an SFTP site using an 'expect' script and put it on HDFS.
#
# Feed file format:
#   SFTP_SOURCE_DIR FILE_PREFIX HDFS_TARGET_DIR
#   /Data/Outbound/Curves USD_TREASURY_ /user/wre/wrelib/curves
#######

DATE_WITHOUT_DASHES=false

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
    --date)
      shift
      DT=$1
      shift
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

# Create a temp directory
BASE_OUTPUT_DIR=$( mktemp -d /tmp/transfer_XXXXXXX )

exec< $FEED_FILE

while read line ; do
    ar=( $line )

    # Skip Comment lines
    s1=$line
    s2=#

    # Skip Commented lines
    if [ "${s1:0:${#s2}}" != "$s2" ]; then

        SRC_DIR="${ar[0]}"
        SRC_FILE="${ar[1]}_${DT}*.csv"
        TARGET_DIR="${ar[2]}"

        echo "Getting  ${SRC_FILE} files from sftp"

        expect -f ${EXPECT_SCRIPT} ${SSH_PORT} ${SSH_USER} ${SSH_HOST} ${SRC_DIR} ${SRC_FILE} ${BASE_OUTPUT_DIR} ${SSH_PASSWORD}

        echo "Push file(s) ${SRC_FILE} to HDFS Directory: ${TARGET_DIR}"
        hdfs dfs -copyFromLocal -f ${BASE_OUTPUT_DIR}/*.* $TARGET_DIR

    fi
done

