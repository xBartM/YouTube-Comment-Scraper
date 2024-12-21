#!/bin/sh

# run if you want to drop the schema

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ];  then
    echo "YTKP_DIR is not set."
    exit 1
fi

# create schema as current user
psql --echo-all --username="$(whoami)" --dbname=postgres --file=${YTKP_DIR}/database/drop_schema.sql
