#!/bin/sh

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] then
    echo "YTKP_DIR is not set."
    exit 1
fi

# get sorted list of all channels (URLs) from channel table. It is guaranteed to be unique
psql \
 --dbname=postgres \
 --tuples-only \
 --command="SELECT channel_url FROM ytkp.channel ORDER BY channel_url;" \
 --output=${YTKP_DIR}/database/temp/db_channels.txt

# sort and remove duplicates from users channel list
sort \
 --unique \
 --output=${YTKP_DIR}/channels.txt \
 ${YTKP_DIR}/channels.txt

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

# run INSERT INTO

# run DELETE FROM

# remove temp files
# ${YTKP_DIR}/database/temp/db_channels.txt
# ${YTKP_DIR}/database/temp/db_channels_insert.txt
# ${YTKP_DIR}/database/temp/db_channels_insert.sql
# ${YTKP_DIR}/database/temp/db_channels_delete.txt
# ${YTKP_DIR}/database/temp/db_channels_delete.sql

