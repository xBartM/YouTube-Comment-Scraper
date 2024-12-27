#!/bin/sh
# this script adds vid URLs to ytkp.video
# running this script will:
# 1. get the channel URL which has the lowest scrape_date, but older than 30 (?) days and store it in a temp file
# 2. append to the temp file channel_url+playlists
# 3. run yt-dlp with config dl-urls.conf to obtain a list of all videos on the channel and playlists
# 4. sort and remove duplicates from the list of videos
# 5. insert into database; on conflict do nothing (if there is a duplicate of the video)
# 6. update scrape_date in channel table

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] ; then
    echo "YTKP_DIR is not set."
    exit 1
fi

# get the top channel URL from the channel table
psql \
 --dbname=postgres \
 --tuples-only \
 --no-align \
 --command="SELECT channel_url FROM ytkp.channel WHERE scrape_date < NOW() - INTERVAL '30 days' ORDER BY scrape_date ASC, insert_date ASC LIMIT 1;" \
 --output=${YTKP_DIR}/database/temp/db_channel.txt

# append a new line consisting of channel_url+/playlists
echo "$(cat ${YTKP_DIR}/database/temp/db_channel.txt)/playlists" >> ${YTKP_DIR}/database/temp/db_channel.txt

# run yt-dlp to save URLs of all the videos on channel; this will append all URLs to the specified file
yt-dlp \
 --config-locations ${YTKP_DIR}/configs/dl-urls.conf \
 --batch-file ${YTKP_DIR}/database/temp/db_channel.txt

# sort and remove duplicates from the list of videos
sort \
 --unique \
 --output=${YTKP_DIR}/archive/vid_urls.txt \
 ${YTKP_DIR}/archive/vid_urls.txt

# create INSERT INTO .sql with ON CONFLICT clause
awk \
 '{ print "INSERT INTO ytkp.video (video_url) VALUES (\x27"$0"\x27) ON CONFLICT (video_url) DO NOTHING;" }' \
 ${YTKP_DIR}/archive/vid_urls.txt \
 > ${YTKP_DIR}/database/temp/db_video_urls_insert.sql

# run INSERT INTO if there is anything to insert
if [ -s ${YTKP_DIR}/database/temp/db_video_urls_insert.sql ] ; then
  psql \
   --dbname=postgres \
   --quiet \
   --file=${YTKP_DIR}/database/temp/db_video_urls_insert.sql
fi

# update scrape_date in channel row
head -1 ${YTKP_DIR}/database/temp/db_channel.txt | \
 awk '{ print "UPDATE ytkp.channel SET scrape_date = NOW() WHERE channel_url = \x27"$0"\x27;" }' \
 > ${YTKP_DIR}/database/temp/db_channel_update_scrape_date.sql

# run the scrape date update script
if [ -s ${YTKP_DIR}/database/temp/db_channel_update_scrape_date.sql ] ; then
  psql \
   --dbname=postgres \
   --quiet \
   --file=${YTKP_DIR}/database/temp/db_channel_update_scrape_date.sql
fi

# remove temp files
rm ${YTKP_DIR}/database/temp/db_channel.txt
rm ${YTKP_DIR}/database/temp/db_video_urls_insert.sql
rm ${YTKP_DIR}/database/temp/db_channel_update_scrape_date.sql
