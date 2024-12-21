#!/bin/sh

# run after every schema drop

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ];  then
    echo "YTKP_DIR is not set."
    exit 1
fi

# create schema as current user
psql --echo-all --username="$(whoami)" --dbname=postgres --file=${YTKP_DIR}/database/create_schema.sql
