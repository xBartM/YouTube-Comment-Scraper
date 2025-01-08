#!/bin/sh
# this script adds ARCHIVAL vid URLs to ytkp.video
# running this script will:
# 1. get all video URLs from the archive and create an INSERT INTO script from them
# 2. run INSERT INTO commands
# 3. remove temp files

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] ; then
    echo "${0##*/}: YTKP_DIR is not set."
    exit 1
fi

# create INSERT INTO .sql with ON CONFLICT clause
awk \
  '{ print "INSERT INTO ytkp.video (video_url) VALUES (\047"$0"\047) ON CONFLICT (video_url) DO NOTHING;" }' \
  ${YTKP_DIR}/archive/vid_urls.txt \
  > ${YTKP_DIR}/database/temp/db_archive_urls_insert.sql

# run INSERT INTO if there is anything to insert
if [ -s ${YTKP_DIR}/database/temp/db_archive_urls_insert.sql ] ; then
    psql \
      --dbname=postgres \
      --quiet \
      --file=${YTKP_DIR}/database/temp/db_archive_urls_insert.sql
fi

# remove temp files
rm ${YTKP_DIR}/database/temp/db_archive_urls_insert.sql
