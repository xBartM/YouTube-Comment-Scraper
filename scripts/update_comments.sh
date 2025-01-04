#!/bin/sh


jq \
  --raw-output \
  '(["UPDATE ytkp.video ",
     "SET video_avail = '\''", .availability, "'\'' ",
       ", video_lang = '\''", .language, "'\'' ",
       ", video_name = '\''", .title, "'\'' ",
       ", video_description = '\''", .description, "'\'' ",
       ", upload_date = '\''", .upload_date, "'\'' ",
       ", scrape_date = CURRENT_TIMESTAMP ",
     "WHERE video_yt_id = '\''", .id, "'\''"] | add)' \
  archive/Stuff_Made_Here_2_20220420_How_to_take_the_trash_out_at_50mph_shorts.info.json
