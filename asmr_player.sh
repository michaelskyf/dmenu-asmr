#!/bin/sh

# License: GPLv3
# https://www.gnu.org/licenses/gpl-3.0.en.html
# Made by Michał Kostrzwski <skyflighter.kos@protonmail.com>

# Requirements: yt-dlp, mpv, dmenu
# Should work on all Unix-like systems (tested only on Arch GNU/Linux)

# Plays random asmr video from channels in CHANNELS variable
# Always use the newest version of yt-dlp (from AUR or pip) or else you may encounter problems

# where title and video ID will be saved
CACHEFILE="$XDG_CACHE_HOME/asmr"

# set it to something uncommon, so pkill won't kill random programs ;)
TITLE="asmr-player"

# Select an invidious instance (or any other that is compatible with youtube url and yt-dlp) or simply youtube
INSTANCE="https://yewtu.be"

# one entry = "channel name" "channel id"
CHANNELS=("Czas po deszczu" "UCAiwYuetAcqbx4NBTlvakXw"
	  "DR. T ASMR" "UCgGhVPf9JH9S41mJwJwgNbg")

	channelselect(){
		CHOICE=$(for ((i=0; i<${#CHANNELS[@]}; i+=2)); do echo ${CHANNELS[$i]}; done | sort -h | dmenu -i -p "Select channel:")

		# Find channel ID
		for ((i=0; i<${#CHANNELS[@]}; i+=2))
		do
			if [ $CHOICE == ${CHANNELS[$i]} ]
			then
				CHANNELID=${CHANNELS[$i+1]}
				CHANNELNAME=${CHANNELS[$i]}
			fi
		done
	}
  	channelrandom(){
		AID=$((($RANDOM % (${#CHANNELS[@]}/2)*2)))
		CHANNELID=${CHANNELS[$AID+1]}
		CHANNELNAME=${CHANNELS[$AID]}
	}

# Selection menu
# 1. Select random channel
# 2. Select channel
# 3. if asmr is already playing, give an option to turn it off
IFS=""
case $( (printf "Select random channel\nSelect channel\n"; if [ "$(pgrep -f $TITLE)" ]; then echo "Turn off current ASMR"; fi ) | dmenu -i -p "Select option:") in
	"Turn off current ASMR") pkill -f $TITLE; exit;;
	"Select channel") channelselect;;
	"Select random channel") channelrandom;;
esac

# if user aborted, exit
if [ ! "$CHANNELID" ]
then
	exit
fi

# Get random video ID and title
VIDEOINFO=$(yt-dlp --no-warnings --playlist-random --max-downloads 1 --get-id --get-title "$INSTANCE/channel/${CHANNELID}")

if [ ! "$VIDEOINFO" ]
then
	notify-send "Error: Could not get video info"
	exit
fi

# Send notification with title and author
notify-send "$(echo $VIDEOINFO | head -1) by $CHANNELNAME"

# Play sound ;)
pkill -f $TITLE
echo $VIDEOINFO > $CACHEFILE
mpv --title="$TITLE" --no-video "$INSTANCE/watch?v=$(echo $VIDEOINFO | tail -1)"
notify-send "ASMR stopped playing"
