#!/bin/sh
# this script synchronizes ytkp.channel table with channels.txt file.
# adding an entry to channels.txt and running this script will:
# 1. sort and deduplicate channels.txt
# 2. export URLs from ytkp.channel and sort them
# 3. insert URLs present in channels.txt and not present in ytkp.channel into db
# 4. delete URLs present in ytkp.channel and not present in channels.txt from db

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] ; then
    echo "${0##*/}: YTKP_DIR is not set."
    exit 1
fi

# get a list of all channels (URLs) from channel table
psql \
 --dbname=postgres \
 --tuples-only \
 --no-align \
 --command="SELECT channel_url FROM ytkp.channel;" \
 --output=${YTKP_DIR}/database/temp/db_channels.txt

# sort and remove duplicates from users channel list
sort \
 --unique \
 --output=${YTKP_DIR}/channels.txt \
 ${YTKP_DIR}/channels.txt

# sort and remove duplicates from databases channel list
sort \
 --unique \
 --output=${YTKP_DIR}/database/temp/db_channels.txt \
 ${YTKP_DIR}/database/temp/db_channels.txt

# create a list of channels to INSERT into database
comm \
 -23 \
 ${YTKP_DIR}/channels.txt \
 ${YTKP_DIR}/database/temp/db_channels.txt \
 > ${YTKP_DIR}/database/temp/db_channels_insert.txt

# create a list of channels to DELETE from database
comm \
 -13 \
 ${YTKP_DIR}/channels.txt \
 ${YTKP_DIR}/database/temp/db_channels.txt \
 > ${YTKP_DIR}/database/temp/db_channels_delete.txt

# create INSERT INTO .sql
awk \
 '{ print "INSERT INTO ytkp.channel (channel_url) VALUES (\x27"$0"\x27);" }' \
 ${YTKP_DIR}/database/temp/db_channels_insert.txt \
 > ${YTKP_DIR}/database/temp/db_channels_insert.sql

# create DELETE FROM .sql
awk \
 '{ print "DELETE FROM ytkp.channel WHERE channel_url = \x27"$0"\x27;" }' \
 ${YTKP_DIR}/database/temp/db_channels_delete.txt \
 > ${YTKP_DIR}/database/temp/db_channels_delete.sql

# run INSERT INTO if there is anything to insert
if [ -s ${YTKP_DIR}/database/temp/db_channels_insert.sql ] ; then
  psql \
   --dbname=postgres \
   --quiet \
   --file=${YTKP_DIR}/database/temp/db_channels_insert.sql
fi

# run DELETE FROM if there is anything to delete
if [ -s ${YTKP_DIR}/database/temp/db_channels_delete.sql ] ; then
  psql \
   --dbname=postgres \
   --quiet \
   --file=${YTKP_DIR}/database/temp/db_channels_delete.sql
fi

# remove temp files
rm ${YTKP_DIR}/database/temp/db_channels.txt
rm ${YTKP_DIR}/database/temp/db_channels_insert.txt
rm ${YTKP_DIR}/database/temp/db_channels_insert.sql
rm ${YTKP_DIR}/database/temp/db_channels_delete.txt
rm ${YTKP_DIR}/database/temp/db_channels_delete.sql

