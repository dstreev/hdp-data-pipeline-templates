#!/usr/bin/env bash

cd `dirname $0`

if [ "${APP_TEMPLATES_BASE}" == "" ]; then
    echo "Please set the following enviroment variables:"
    echo "APP_TEMPLATES_BASE: ${APP_TEMPLATES_BASE}"
    echo "NAMENODE_FS: ${NAMENODE_FS}"
    echo "RSRC_MNGR: ${RSRC_MNGR}"
    echo "USER: ${USER}"
fi

# Assumes current users hdfs home directory.

# Deploy Workflows
hdfs dfs -test -d ${APP_TEMPLATES_BASE} && echo "Base Templates Directory Exists" || hdfs dfs -mkdir ${APP_TEMPLATES_BASE}

cd ../src/main

# Recurse and create all directories
#for i in `find . -type d | grep -v "assembly"`; do
#    hdfs dfs -test -d ${APPS_TEMPLATE_BASE}/${i} && echo "${APPS_TEMPLATE_BASE}/${i} exists" || hdfs dfs -mkdir -p ${APPS_TEMPLATE_BASE}/${i}
#done

hdfs dfs -copyFromLocal -f ./* ${APP_TEMPLATES_BASE}
