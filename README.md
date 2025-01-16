# YouTube Comment Scraper

Scrape comments, descriptions and transcripts from selected YouTube channels (or videos) and insert them into a database.

## Table of Contents

* [General Info](#general-info)
* [Setup](#setup)
* [Run](#run)
* [Endnotes](#endnotes)
* [Future Plans](#future-plans)

## General Info

### Overview

This repository allows you to download YouTube video data (comments, descriptions and transcripts) using `yt-dlp` and store it in a `PostgreSQL` database for further analysis. Below is an overview of how to set up and use this tool.

### Repo structure

> [!NOTE]  
> Every file contains extensive comments to help with understanding what the code's functionality and purpose.

The repository is structured as follows:

`configs`: Configuration files for `yt-dlp` are stored in the `configs/` directory. These files define how videos are downloaded and what metadata is extracted.

`database`: The database schema is defined in `database/create_schema.sql`. It includes tables for channels, videos, comments, transcripts, and sponsorblock data. The `database/` folder also contains `logs/` and `temp/` folders that, while essential for the tool, are not important for the user.

`scripts`: Various scripts in the `scripts/` directory automate tasks like database initialization, video metadata updates, and channel synchronization. More on them in [Setup](#setup) and [Run](#run) sections.

## Setup

> [!CAUTION]  
> If you are using PostgreSQL for other projects, this repository can damage it! Review `scripts/db_*.sh` and `database/*.sql` files and make sure they fit your design.

### Prerequisites

> [!IMPORTANT]  
> I have developed and tested this solution exclusively on [Termux](https://github.com/termux/termux-app) (a terminal emulator for Android OS)

This repo requires the following software:
1. [yt-dlp](https://github.com/yt-dlp/yt-dlp/wiki/Installation#android) - used for downloading comments, descriptions and transcripts from videos.
2. [PostgreSQL](https://www.postgresql.org/download/linux/#generic) - used for storing video data (on `termux` install it by using `pkg`).
3. [jq](https://jqlang.github.io/jq/download/) - Command-line JSON processor (on `termux` install it by using `pkg`).

### Repo init and setup

1. Clone this repository:
	```
	git clone https://github.com/xBartM/YouTube-Comment-Scraper.git
	```
2. Set `YTKP_DIR` environmental variable:  
	1. Navigate to the repository:
		```
		cd /path/to/YouTube-Comment-Scraper
		```
	2. Set `YTKP_DIR` to current directory:
		```
		export YTKP_DIR=$(pwd)
		```
	3. (Optional) update and reload `~/.bashrc` so you don't have to repeat these steps each time you open the terminal:
		```
		echo "export YTKP_DIR=${YTKP_DIR}" >> ~/.bashrc && source ~/.bashrc
		```
3. Create necessary folders:
	```
	mkdir archive archive/temp database/logs database/temp
	```
4. Finish setting up PostgreSQL:
> [!WARNING]  
> termux exclusive! Other systems may vary!
	
	1. Run `scripts/db_init.sh` to create a skeleton database.
	2. Run `scripts/db_start.sh` to start the PostgreSQL server.
	3. Run `scripts/db_create_schema.sh` to create a schema for the project.

## Run

> [!IMPORTANT]  
> Always remember to have `YTKP_DIR` set; scripts won't execute without it.

You can use this repository in two ways:

1. [Channel Scrape](#channel-scrape) - scrape all available videos from a list of channels.
2. [Video Scrape](#video-scrape) - scrape videos from a list of URLs.

### Channel Scrape

> [!NOTE]  
> This tool looks at the videos from `/videos` tab AND goes through all `/playlists`. Videos from other channels may inadvertentl enter the dataset.

> [!NOTE]  
> `/shorts` are not scraped.

1. Populate `channels.txt` with channel URLs of your choice (note formatting with '@' symbol).
2. Run the `scripts/update_channels.sh` script to sync the database with the `channels.txt` file. 
	> [!NOTE]  
	> This script alters the contents of the `channels.txt` file.
	
	> [!IMPORTANT]  
	> Removing a channel from the `channels.txt` file and running this script will remove that channel from the database (video data will persist but without the knowledge of the channel).
3. Run the `scripts/update_videos.sh` script to fetch video URLs for the top channel.
	> [!NOTE]  
	> This script runs for the top channel from the DB sorted by `scrape_date asc` and `insert_date asc`. Multiple passes of this script are necessary for scraping multiple channels.
	
	> [!TIP]  
	> You can run this script in a loop until it exits with an error, e.g.:  
	> ```
	> for i in {1..100}; do sh scripts/update_videos.sh || break; done
	> ```

	> [!NOTE]
	> This script alters the contents of the `archive/vid_urls.txt` file.
4. Continue to the [Data Scrape](#data-scrape) section.

### Video Scrape

1. Populate `archive/vid_urls.txt` with video URLs of your choice (note formatting as `https://www.youtube.com/watch?v={11-char vid ID}`).
2. Run the `scripts/insert_videos.sh` script to save all video URLs to the database.
	> [!IMPORTANT]  
	> This script only inserts URLs; there is no data on the channel.
	
	> [!NOTE]
	> This script alters the contents of the `archive/vid_urls.txt` file.
3. Continue to the [Data Scrape](#data-scrape) section.

### Data Scrape

1. Run the `scripts/update_metadata.sh` script to download comments, description and transcript for the top video in the database.
	> [!NOTE]  
	> This script runs for the top video from the DB sorted by `scrape_date asc` and `insert_date asc`. Multiple passes of this script are necessary for scraping multiple videos.
	
	> [!TIP]  
	> You can run this script in a loop until it exits with an error, e.g.:  
	> ```
	> for i in {1..100}; do sh scripts/update_metadata.sh || break; done
	> ```

## Endnotes

* next time, use a higher-level language (ex. Python) as it would save SIGNIFICANT amount of time and enhance portability;
* next time, dump all data into the database firts and then select what's important (this saves time during development and allows for an access to other data if the need arises);
* next time, start with a `README.md` and/or a documentation;
* next time, write tests and add debugging options;
* next time, utilise more tools than just an emulated terminal window with `nano` :)

## Future Plans

YTKP stands for YouTube Knowledge Project. I started developing it for multiple reasons:

1. Tech Search:
	1. There are many communities that provide difficult-to-obtain and/or high-tech knowledge in an accessible way (e.g. Applied Science, Thought Emporium, Easy Composites).
	2. Video transcripts can be used for Semantic Search, for RAG, or other forms of NLP that would enhance the knowledge base of an individual.
	3. The comment section can be a place where other high-end specialists explain certain phonomena; however discerning credibility can be challenging.
	4. Google Search is non-functional at best, straight incompetent/wrong/flawed at worst (even sponsored search results would be passible if they were at least in the ballpark of the right answear).
	
2. Sentiment analysis:
	1. YouTube is a global media platform with (probably) the strongest mechanisms for maintaining information bubbles.
	2. It presents an interesting proposition for opinion-forming within the society.
	3. This all in turn can provide data about the agenda of parties interested in such practices. Ex:
		1. pushing multiple videos across various channels as a PR stunt to get goodwill after scandals.
		2. disseminating political propaganda on both local and global level.
		3. focusing on certain news while ignoring others to drive their (or their payers') agenda.
		4. many, many more use cases exist.
	4. Comments (probably) being mostly written by bought bots can shed some more light on the sentiment that someone is trying to force upon the target audience.