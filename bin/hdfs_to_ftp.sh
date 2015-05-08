#!/bin/bash

#######
# Get file from an FTP site and put it on HDFS.
#
#
# Feed file format:
#   HDFS_SOURCE_DIR FILE_PREFIX FTP_TARGET_DIR
#   <hdfs_source_dir> <file_prefix> <ftp_target_dir>
#######

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

DATE_VAR=${DATE_VAR:-reporting_dt}

if [ -f ${FTP_ENV} ]; then
    . ${FTP_ENV}
else
    echo "Can't locate environment file ${FTP_ENV}"
    exit -1
fi

# Create a temp directory
BASE_OUTPUT_DIR=$( mktemp -d /tmp/transfer_XXXXXXX )

GOOD_DT="${DT:0:4}-${DT:4:2}-${DT:6:2}"

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

        # Fetch Files generated by Quantlib from the FTP Site.
        FULL_FILE="${PREFIX}${GOOD_DT}.csv"

        echo "Get file ${FULL_FILE} from HDFS Directory: ${SOURCE_DIR}"
        hdfs dfs -get ${SOURCE_DIR}/${FULL_FILE} ${BASE_OUTPUT_DIR}


        ftp -in <<EOF
        open $FTP_HOST
        user $FTP_USER $FTP_PASSWORD
        cd $TARGET_DIR
        lcd ${BASE_OUTPUT_DIR}
        mput ${FULL_FILE}
        quit
EOF

    fi
done

