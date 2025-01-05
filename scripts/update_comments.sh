#!/bin/sh
# this script adds vid metadata to ytkp.video AND vid comments to ytkp.comment_section
# running this script will:
# 1. TODO


# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] ; then
    echo "${0##*/}: YTKP_DIR is not set."
    exit 1
fi

# get the top video URL from the video table
db_video=$( \
  psql \
    --dbname=postgres \
    --tuples-only \
    --no-align \
    --command="SELECT video_url FROM ytkp.video WHERE scrape_date < NOW() - INTERVAL '30 days' ORDER BY scrape_date ASC, insert_date ASC LIMIT 1;"
)

# check if there is work to do
if [ -z "${db_video}" ] ; then
    echo "${0##*/}: no work to do. exitting"
    exit 1
fi

# download the metadata along with the comments
yt-dlp \
  --config-locations ./configs/dl-texts.conf \
  "${db_video}"

# create update video data DML script
jq \
  --raw-output \
  '(["UPDATE ytkp.video ",
     "SET channel_id = ytkp.find_channel_id('\''", .uploader_id, "'\'') ",
       ", video_avail = '\''", .availability, "'\'' ",
       ", video_lang = '\''", .language, "'\'' ",
       ", video_name = '\''", .title, "'\'' ",
       ", video_description = '\''", .description, "'\'' ",
       ", upload_date = '\''", .upload_date, "'\'' ",
       ", scrape_date = CURRENT_TIMESTAMP ",
     "WHERE video_yt_id = '\''", .id, "'\'';"] | add)' \
  ${YTKP_DIR}/archive/temp/*info.json \
  > ${YTKP_DIR}/database/temp/db_insert_video_data.sql

# append insert comment_section data DML script to existing file (from above)
jq \
  --raw-output \
  '(["INSERT INTO ytkp.comment_section (",
       "comment_yt_id, comment_yt_parent, video_id, user_name, comment_text",
       ", like_count, is_verified, is_favourited, is_pinned, comment_date",
     ") VALUES ",
    ([.comments[] + {vid_id: .id} |
     [
       "('\''", .id, "'\'' ",
       ", '\''", .parent, "'\'' ",
       ", ytkp.find_video_id('\''", .vid_id, "'\'') ",
       ", '\''", .author, "'\'' ",
       ", '\''", (.text | gsub("'\''";"'\'''\''")), "'\'' ",
       ", ", .like_count, " ",
       ", ", .author_is_verified, " ",
       ", ", .is_favorited, " ",
       ", ", .is_pinned, " ",
       ", to_timestamp(", .timestamp, "))"
     ] | join("")
    ] | join(",\n") + ";")] | join(""))' \
  ${YTKP_DIR}/archive/temp/*info.json \
  >> ${YTKP_DIR}/database/temp/db_insert_video_data.sql

# update video data and add comments
psql \
  --dbname=postgres \
  --quiet \
  --file=${YTKP_DIR}/database/temp/db_insert_video_data.sql

# do some things with video transcript so it's readable
error()

# move data files from temp dir to archive for storage
mv \
  ${YTKP_DIR}/archive/temp/*info.json \
  ${YTKP_DIR}/archive/

# remove temp files
rm ${YTKP_DIR}/database/temp/db_insert_video_data.sql

