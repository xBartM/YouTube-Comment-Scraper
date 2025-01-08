#!/bin/sh
# this script adds vid URLs to ytkp.video
# running this script will:
# 1. get the channel URL which has the lowest scrape_date, but older than 30 (?) days and store it in a temp file
# 2. run yt-dlp with config dl-urls.conf to obtain a list of all videos on the channel and playlists
# 3. sort and remove duplicates from the list of videos
# 4. insert into database; on conflict do nothing (if there is a duplicate of the video)
# 5. update scrape_date in channel table
# 6. update archival vid_urls.txt file

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] ; then
    echo "${0##*/}: YTKP_DIR is not set."
    exit 1
fi

# get the top channel URL from the channel table
db_channel=$( \
  psql \
    --dbname=postgres \
    --tuples-only \
    --no-align \
    --command="SELECT channel_url FROM ytkp.channel WHERE scrape_date < NOW() - INTERVAL '30 days' ORDER BY scrape_date ASC, insert_date ASC LIMIT 1;"
)

# check if there is work to do
if [ -z "${db_channel}" ] ; then
    echo "${0##*/}: no work to do. exitting"
    exit 1
fi

# run yt-dlp to save URLs of all videos from the channel
yt-dlp \
  --config-locations ${YTKP_DIR}/configs/dl-urls.conf \
  --print-to-file url ${YTKP_DIR}/archive/temp/video_urls.txt \
  "${db_channel}"

# run yt-dlp to save URLs of all playlists from the channel
yt-dlp \
  --config-locations ${YTKP_DIR}/configs/dl-urls.conf \
  --print-to-file url ${YTKP_DIR}/archive/temp/playlist_urls.txt \
  "${db_channel}/playlists"

# run yt-dlp to expand playlists into a list of video URLs; this will append all URLs to the specified file
yt-dlp \
  --config-locations ${YTKP_DIR}/configs/dl-urls.conf \
  --print-to-file url ${YTKP_DIR}/archive/temp/video_urls.txt \
  --batch-file ${YTKP_DIR}/archive/temp/playlist_urls.txt

# remove shorts. write to temp file and then mv back to the original file
awk \
  '!/shorts/' \
  ${YTKP_DIR}/archive/temp/video_urls.txt \
  > ${YTKP_DIR}/archive/temp/video_urls.txt.tmp \
  && mv ${YTKP_DIR}/archive/temp/video_urls.txt.tmp ${YTKP_DIR}/archive/temp/video_urls.txt

# sort and remove duplicates from the list of videos
sort \
  --unique \
  --output=${YTKP_DIR}/archive/temp/video_urls.txt \
  ${YTKP_DIR}/archive/temp/video_urls.txt

# create INSERT INTO .sql with ON CONFLICT clause
awk \
  '{ print "INSERT INTO ytkp.video (video_url) VALUES (\x27"$0"\x27) ON CONFLICT (video_url) DO NOTHING;" }' \
  ${YTKP_DIR}/archive/temp/video_urls.txt \
  > ${YTKP_DIR}/database/temp/db_video_urls_insert.sql

# run INSERT INTO if there is anything to insert
if [ -s ${YTKP_DIR}/database/temp/db_video_urls_insert.sql ] ; then
    psql \
      --dbname=postgres \
      --quiet \
      --file=${YTKP_DIR}/database/temp/db_video_urls_insert.sql
fi

# update scrape_date in channel row
psql \
  --dbname=postgres \
  --quiet \
  --command="UPDATE ytkp.channel SET scrape_date = NOW() WHERE channel_url = '${db_channel}';"

# update archival vid_urls.txt file
cat \
  ${YTKP_DIR}/archive/temp/video_urls.txt \
  >> ${YTKP_DIR}/archive/vid_urls.txt
sort \
  --unique \
  --output=${YTKP_DIR}/archive/vid_urls.txt \
  ${YTKP_DIR}/archive/vid_urls.txt

# remove temp files
rm ${YTKP_DIR}/archive/temp/video_urls.txt
rm ${YTKP_DIR}/archive/temp/playlist_urls.txt
rm ${YTKP_DIR}/database/temp/db_video_urls_insert.sql
