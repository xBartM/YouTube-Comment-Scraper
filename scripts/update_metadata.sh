#!/bin/sh
# this script adds vid metadata to ytkp.video AND vid comments to ytkp.comment_section AND vid transcript to ytkp.video_transcript
# running this script will:
# 1. Get the ID i URL of the video to scrape from the database. nothing happens when nothing is selected
# 2. Run yt-dlp to scrape video data, comments, sponsored segments and transcript
# 3. Create an DML script for the database to:
## 3a. Insert scraped video information into ytkp.video table
## 3b. Insert scraped comment section into ytkp.comment_section table
## 3c. Insert scraped video transcript into ytkp.video_transcript table
## 3d. Insert scraped info about sponsored segments into ytkp.sponsorblock table
# 4. Run the DML script
# 5. Move raw video data and transcript files to archive dir
# 6. Remove temp files

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] ; then
    echo "${0##*/}: YTKP_DIR is not set."
    exit 1
fi

# get the top video ID and URL from the video table
db_video=$( \
  psql \
    --dbname=postgres \
    --tuples-only \
    --no-align \
    --command="SELECT video_id, video_url FROM ytkp.video WHERE scrape_date < NOW() - INTERVAL '30 days' ORDER BY scrape_date ASC, insert_date ASC LIMIT 1;"
)

# check if there is work to do
if [ -z "${db_video}" ] ; then
    echo "${0##*/}: no work to do. exitting"
    exit 1
fi

# split the db_video variable to video ID and video URL for use later
db_video_id=${db_video%|*}
db_video_url=${db_video#*|}
# find data file names
vid_data=$(ls ${YTKP_DIR}/archive/temp/*info.json | head -1)
vid_transcript=$(ls ${YTKP_DIR}/archive/temp/*vtt | head -1)

# download the metadata along with the comments
yt-dlp \
  --config-locations ./configs/dl-texts.conf \
  "${db_video_url}"

# create UPDATE video data DML script
jq \
  --raw-output \
  '(["UPDATE ytkp.video ",
     "SET channel_id = ytkp.find_channel_id('\''", .uploader_id, "'\'') ",
       ", video_avail = '\''", .availability, "'\'' ",
       ", video_lang = '\''", .language, "'\'' ",
       ", video_name = '\''", (.title | gsub("'\''";"'\'''\''")), "'\'' ",
       ", video_description = '\''", (.description | gsub("'\''";"'\'''\''")), "'\'' ",
       ", upload_date = '\''", .upload_date, "'\'' ",
       ", scrape_date = CURRENT_TIMESTAMP ",
     "WHERE video_yt_id = '\''", .id, "'\'';"] | add)' \
  ${vid_data} \
  > ${YTKP_DIR}/database/temp/db_insert_video_data.sql

# append INSERT comment_section data DML script to existing file (from above)
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
  ${vid_data} \
  >> ${YTKP_DIR}/database/temp/db_insert_video_data.sql

# append INSERT video_transcript data DML script to existing file (from above)
awk -v vid_id="$db_video_id" \
  'BEGIN {
       # Initialize the SQL statement
       sql = "INSERT INTO ytkp.video_transcript\n(video_id, start_time, end_time, transcript_text) VALUES\n"
       first_entry = 1
  }

  # Match lines with timestamps
  /^([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}) --> ([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3})/ {
      if (!first_entry) {
          sql = sql ",\n"
      }
      start_time = $1
      end_time = $3
      getline # Read the next line for transcript text
      transcript_text = $0

      # Replace single quotes with two single quotes in transcript_text
      gsub("'\''", "'\'''\''", transcript_text)

      # Append the values to the SQL statement
      sql = sql "(" vid_id ", '\''" start_time "'\'', '\''" end_time "'\'', '\''" transcript_text "'\'')"

      first_entry = 0
  }

  END {
      # Print the final SQL statement
      print sql ";"
  }'\
  ${vid_transcript} \
  >> ${YTKP_DIR}/database/temp/db_insert_video_data.sql

# append INSERT sponsorblock data DML script to existing file (from above)
jq \
  --raw-output \
  '(["INSERT INTO ytkp.sponsorblock (",
       "video_id, start_time, end_time",
     ") VALUES ",
    ([.sponsorblock_chapters[] + {vid_id: .id} |
     [
       "(ytkp.find_video_id('\''", .vid_id, "'\'') ",
       ", make_interval(secs => ", .start_time, ")::TIME ",
       ", make_interval(secs => ", .end_time, ")::TIME)"
     ] | join("")
    ] | join(",\n") + ";")] | join(""))' \
  ${vid_data} \
  >> ${YTKP_DIR}/database/temp/db_insert_video_data.sql

# update video data, add comments, add transcript and add sponsorblock data
psql \
  --dbname=postgres \
  --quiet \
  --file=${YTKP_DIR}/database/temp/db_insert_video_data.sql

# move data files from temp dir to archive for storage
mv \
  ${vid_data} \
  ${vid_transcript} \
  ${YTKP_DIR}/archive/

# remove temp files
rm ${YTKP_DIR}/database/temp/db_insert_video_data.sql
