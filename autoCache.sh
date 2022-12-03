#!/bin/bash

#font color
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# The path to the local cache folder
COMPATDATA_PATH="/home/deck/.steam/steam/steamapps/compatdata"
SHADERCACHE_PATH="/home/deck/.steam/steam/steamapps/shadercache"

# Now get the SD card path
declare -a DISKS
DISKS=($(df -h --total | grep media | awk '{print $1, $6, $2, $4}'))
SD_PATH=$(zenity --list --width=700 --height=200 --title="Select the disk" --text="Select the disk where you want to move the cache" --column="Disk" --column="Path" --column="Size" --column="Free space"  --print-column="2" "${DISKS[@]}")
clear
printf "You selected: |%s| \n" "$SD_PATH"
if [ ! -d "$SD_PATH/steamapps" ]; then
	#if there is a SteamLibrary folder change SD_PATH to the SteamLibrary folder
	if [ -d "$SD_PATH/SteamLibrary" ]; then
		SD_PATH="$SD_PATH/SteamLibrary"
	fi
fi

if [ ! -d "$SD_PATH/steamapps" ]; then
	zenity --question --width=700  --title="Steamapps folder missing" --text="The steamapps folder seems to be missing on the sd card, do you want to manually select steamapps folder ?"
	if [ $? -eq 0 ]; then
		SD_PATH=$(zenity  --file-selection --directory  --filename=/run/media/ --title="Select the sd steamapps folder")
		#remove /steamapps from the path
		SD_PATH=$(echo "$SD_PATH" | sed 's/\/steamapps//g')
		clear
		printf "You selected: %s \n" "$SD_PATH"
		if [ ! -d "$SD_PATH/steamapps" ]; then
			zenity --error --width=700 --title="Steamapps folder missing" --text="The steamapps folder is missing on the sd card."
			exit 1
        else
            #Check that the folder is not on the internal drive
            if [ "$SD_PATH" == "/home/deck/.steam/steam" ]; then
                zenity --error --width=700 --title="Bad path" --text="The steamapps folder you selected is on the internal drive. Please select a steamapps folder on an external drive."
                exit 1
            fi
        fi
	else
		clear
		zenity --error --width=700 --title="No folder selected" --text="You didn't select a folder, exiting."
		exit 1
	fi
fi
GAME_PATH="$SD_PATH/steamapps/common"
STEAMAPPS_PATH="$SD_PATH/steamapps/"

if [ -z "$(ls -A $STEAMAPPS_PATH)" ]; then
	zenity --error --width=700 --title="Steamapps folder empty" --text="The steamapps folder seem to be empty or no right to access it."
	exit 1
fi

#Check if the different cache folders exist or create them
if [ ! -d "$SD_PATH/cache" ]; then
    mkdir "$SD_PATH/cache"
fi

if [ ! -d "$SD_PATH/cache/compatdata" ]; then
    mkdir "$SD_PATH/cache/compatdata"
fi

if [ ! -d "$SD_PATH/cache/shadercache" ]; then
    mkdir "$SD_PATH/cache/shadercache"
fi

#Create a list of all the games in the sd card with the app_manifest_*.acf files
declare -a GAMES
for game in "$STEAMAPPS_PATH"/appmanifest_*.acf; do
    space=0
    spaceHuman=0
    game_id=$(basename "$game" | cut -d'_' -f2 | cut -d'.' -f1)
    game_name=$(grep -m 1 "name" "$game" | cut -d'"' -f4)
    if [ ! -L "$SHADERCACHE_PATH/$game_id" ] || [ ! -L "$COMPATDATA_PATH/$game_id" ]; then
        if  [ -d "$COMPATDATA_PATH/$game_id" ] && [ ! -L "$COMPATDATA_PATH/$game_id" ]; then
                space+=$(du -sb "$COMPATDATA_PATH/$game_id" | cut -f1)
        fi
        if [ -d "$SHADERCACHE_PATH/$game_id" ] && [ ! -L "$SHADERCACHE_PATH/$game_id" ]; then
                space+=$(du -sb "$SHADERCACHE_PATH/$game_id" | cut -f1)
        fi
        spaceHuman=$(numfmt --to=iec-i --suffix=B --padding=7 $space)
        if [ $space -ne 0 ]; then
            GAMES+=("FALSE" "$game_id" "$game_name" "$spaceHuman")
        fi
    fi
done

if [ ${#GAMES[@]} -eq 0 ]; then
    zenity --info --width=700 --title="No game to move" --text="There is no game to move"
    exit 0
fi
#zenity prompt user to choose the games cache to move
GAMES_CHOSEN=$(zenity --list --width=700 --height=500 --title="Select the games" --text="These games were found on the selected external drive and have their cache on the internal storage. Select them to move their cache to the selected drive" --column="Move?" --column="Appid" --column="Game" --column="Cache size" --checklist --print-column="2" "${GAMES[@]}" --separator=" ")
clear
GAMES_CHOSEN=($GAMES_CHOSEN)
LOCAL_SPACE=$(df -BM --total "/home/deck" | grep total | awk '{print $4}' | sed 's/M//g')

if [ -z "$GAMES_CHOSEN" ]; then
    zenity --error --title="No games selected" --width=700 --text="You didn't select any games."
    exit 1
else
    (
    toPrint="[RESULTS]\n"
    gamepercent=$((100/${#GAMES_CHOSEN[@]}))
    printf "gamepercent: %s \n" "$gamepercent"
    i=0
    for game in "${GAMES_CHOSEN[@]}"; do
        game_name=$(grep -m 1 "name" "$STEAMAPPS_PATH/appmanifest_$game.acf" | cut -d'"' -f4)
        echo $i
        echo "# Moving cache for game $game_name ($game)"
         #check if the game has a compatdata folder and if it's not a symlink then move it to the sd card and create a symlink
        if [ -d "$COMPATDATA_PATH/$game" ]; then
            if [ ! -L "$COMPATDATA_PATH/$game" ];then
                #check if there is enough space on the sd card to move the cache
                if [ $(df -B1 "$SD_PATH" | tail -1 | awk '{print $4}') -gt $(du -sb "$COMPATDATA_PATH/$game" | cut -f1) ]; then
                    mv "$COMPATDATA_PATH/$game" "$SD_PATH/cache/compatdata/"
                    ln -s "$SD_PATH/cache/compatdata/$game" "$COMPATDATA_PATH"
                    printf "${GREEN}Moved compatdata for %s (%s) to the sd card${NC} \n" "$game_name" "$game"
                    toPrint+="${GREEN}Moved compatdata for $game_name ($game) to the sd card${NC} \n"
                else
                    printf "${RED}Not enough space on the sd card to move compatdata for %s (%s)${NC} \n" "$game_name" "$game"
                    toPrint+="${RED}Not enough space on the sd card to move compatdata for $game_name ($game)${NC} \n"
                fi
            else
                printf "${ORANGE}Compatdata for %s (%s) is already on the sd card (or at least it's already a symlink)${NC} \n" "$game_name" "$game"
                toPrint+="${ORANGE}Compatdata for $game_name ($game) is already on the sd card (or at least it's already a symlink)${NC} \n"
            fi
        else
            printf "${ORANGE}Compatdata for %s (%s) does not seem to exist${NC} \n" "$game_name" "$game"
            toPrint+="${ORANGE}Compatdata for $game_name ($game) does not seem to exist${NC} \n"
        fi
        #Same for the shadercache
        if [ -d "$SHADERCACHE_PATH/$game" ]; then
            if [ ! -L "$SHADERCACHE_PATH/$game" ]; then
                if [ $(df -B1 "$SD_PATH" | tail -1 | awk '{print $4}') -gt $(du -sb "$SHADERCACHE_PATH/$game" | cut -f1) ]; then
                    mv "$SHADERCACHE_PATH/$game" "$SD_PATH/cache/shadercache/"
                    ln -s "$SD_PATH/cache/shadercache/$game" "$SHADERCACHE_PATH"
                    printf "${GREEN}Moved shadercache for %s (%s) to the sd card${NC} \n" "$game_name" "$game"
                    toPrint+="${GREEN}Moved shadercache for $game_name ($game) to the sd card${NC} \n"
                else
                    printf "${RED}Not enough space on the sd card to move the shadercache for %s (%s)${NC} \n" "$game_name" "$game"
                    toPrint+="${RED}Not enough space on the sd card to move the shadercache for $game_name ($game)${NC} \n"
                fi
            else
                printf "${ORANGE}Shadercache for %s (%s) is already on the sd card (or at least it's already a symlink)${NC} \n" "$game_name" "$game"
                toPrint+="${ORANGE}Shadercache for $game_name ($game) is already on the sd card (or at least it's already a symlink)${NC} \n"
            fi
        else
            printf "${ORANGE}Shadercache for %s (%s) does not seem to exist${NC} \n" "$game_name" "$game"
            toPrint+="${ORANGE}Shadercache for $game_name ($game) does not seem to exist${NC} \n"
        fi
        printf "\n"
        toPrint+="\n"
        i=$((i+gamepercent))
    done 
    LOCAL_SPACE_AFTER=$(df -BM --total "/home/deck" | grep total | awk '{print $4}' | sed 's/M//g')
    LOCAL_SPACE_DIFF=$((LOCAL_SPACE_AFTER-LOCAL_SPACE))
    toPrint+="${GREEN}You gained $LOCAL_SPACE_DIFF MB of space on your local disk${NC} \n"
    echo -e "$toPrint" > "/tmp/steamcache.log" ) | zenity --progress --title="Moving cache to the sd card" --text="Moving cache to the sd card" --auto-close 
fi
konsole --hold -e "cat /tmp/steamcache.log" && rm -f /tmp/steamcache.log