-- Create a new schema
CREATE SCHEMA ytkp;


-- Create the channel table
CREATE TABLE  ytkp.channel (
    channel_id SERIAL PRIMARY KEY,
    channel_url VARCHAR(255) NOT NULL,
    channel_name VARCHAR(255)
);

-- Add comments for the channel table and its columns
COMMENT ON TABLE ytkp.channel IS 'Table containing channel information';
COMMENT ON COLUMN ytkp.channel.channel_id IS 'Unique identifier for each channel, auto-incremented';
COMMENT ON COLUMN ytkp.channel.channel_url IS 'URL of the channel, must be provided';
COMMENT ON COLUMN ytkp.channel.channel_name IS 'Name of the channel, derived from the channel_url';


-- Create the video table
CREATE TABLE ytkp.video (
    video_id SERIAL PRIMARY KEY,
    channel_id INT REFERENCES ytkp.channel(channel_id),
    video_url VARCHAR(255) NOT NULL,
    video_name VARCHAR(255),
    video_description TEXT
);

-- Add comments for the video table and its columns
COMMENT ON TABLE ytkp.video IS 'Table containing video information';
COMMENT ON COLUMN ytkp.video.video_id IS 'Unique identifier for each video, auto-incremented';
COMMENT ON COLUMN ytkp.video.channel_id IS 'Foreign key referencing the associated channel';
COMMENT ON COLUMN ytkp.video.video_url IS 'URL of the video, must be provided';
COMMENT ON COLUMN ytkp.video.video_name IS 'Name of the video';
COMMENT ON COLUMN ytkp.video.video_description IS 'Description of the video';


-- Create the comment table
CREATE TABLE ytkp.comment_section (
    comment_id SERIAL PRIMARY KEY,
    video_id INT REFERENCES ytkp.video(video_id),
   -- channel_id INT REFERENCES ytkp.channel(channel_id),
    user_name VARCHAR(255),
    comment_text TEXT
);

-- Add comments for the comment table and its columns
COMMENT ON TABLE ytkp.comment_section IS 'Table containing comments on videos';
COMMENT ON COLUMN ytkp.comment_section.comment_id IS 'Unique identifier for each comment, auto-incremented';
COMMENT ON COLUMN ytkp.comment_section.video_id IS 'Foreign key referencing the associated video';
COMMENT ON COLUMN ytkp.comment_section.user_name IS 'Name of the user that wrote the given comment';
COMMENT ON COLUMN ytkp.comment_section.comment_text IS 'Text of the comment';
