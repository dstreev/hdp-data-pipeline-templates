#!/bin/bash

#######
# Get file from an HDFS site and post it to scp site.
#
#
# Feed file format:
#   HDFS_SOURCE_DIR FILE_PREFIX FTP_TARGET_DIR
#   <source_dir> <file_prefix> <ftp_target_dir>
#######

DATE_WITHOUT_DASHES=false
# Whether to add date as an extension to the output file.
DATE_EXT=true

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
    --no_date_ext)
      shift
      DATE_EXT=false
      ;;
    --date_without_dashes)
        shift
        DATE_WITHOUT_DASHES=true
        ;;
    --date_var)
      shift
      DATE_VAR=$1
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

if [ -f ${SSH_ENV} ]; then
    . ${SSH_ENV}
else
    echo "Can't locate environment file ${SSH_ENV}"
    exit -1
fi

# Create a temp directory
BASE_OUTPUT_DIR=$( mktemp -d /tmp/transfer_XXXXXXX )

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
        if [ "${DATE_EXT}" == "true" ]; then
            TARGET_FILENAME="${ar[1]}.${DT}.csv"
        else
            TARGET_FILENAME="${ar[1]}.csv"
        fi

        REMOTE_TARGET_DIR="${ar[2]}"

        hdfs dfs -get ${SOURCE_DIR}/${TARGET_FILENAME} ${BASE_OUTPUT_DIR}

        # Authenication is based on Key Exchange.
        scp -i ${SSH_KEY_FILE} -P ${SSH_PORT} ${BASE_OUTPUT_DIR}/${TARGET_FILENAME} ${SSH_USER}@${SSH_HOST}:${REMOTE_TARGET_DIR}

    fi
done

