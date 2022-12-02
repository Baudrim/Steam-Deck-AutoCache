#!/bin/bash
# autoCache2.sh - A version of autoCache.sh that uses zenity to display a GUI

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
SD_PATH=$(zenity --list --width=700  --title="Select the disk" --text="Select the disk where you want to move the cache" --column="Disk" --column="Path" --column="Size" --column="Free space"  --print-column="2" "${DISKS[@]}")
clear
printf "You selected: |%s| \n" "$SD_PATH"
# Check if the sd card has a steamapps folder
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
		# Check if the sd card has a steamapps folder
		if [ ! -d "$SD_PATH/steamapps" ]; then
			zenity --error --title="Steamapps folder missing" --text="The steamapps folder is missing on the sd card."
			exit 1
		fi
	else
		clear
		zenity --error --title="No folder selected" --text="You didn't select a folder, exiting."
		exit 1
	fi
fi
GAME_PATH="$SD_PATH/steamapps/common"
STEAMAPPS_PATH="$SD_PATH/steamapps/"
#check if the steamapps folder is empty
if [ ! "$(ls -A $STEAMAPPS_PATH)" ]; then
	zenity --error --title="Steamapps folder empty" --text="The steamapps folder is empty on the sd card."
	exit 1
fi

#Check if the sd card has a cache folder and if not create it
if [ ! -d "$SD_PATH/cache" ]; then
    mkdir "$SD_PATH/cache"
fi

#Check if the sd card has a compatdata folder and if not create it
if [ ! -d "$SD_PATH/cache/compatdata" ]; then
    mkdir "$SD_PATH/cache/compatdata"
fi

#Check if the sd card has a shadercache folder and if not create it
if [ ! -d "$SD_PATH/cache/shadercache" ]; then
    mkdir "$SD_PATH/cache/shadercache"
fi

#Create a list of all the games in the sd card with the app_manifest_*.acf files
declare -a GAMES
for game in "$STEAMAPPS_PATH"/appmanifest_*.acf; do
    space=0
    spaceHuman=0
    # get the game id
    game_id=$(basename "$game" | cut -d'_' -f2 | cut -d'.' -f1)
    # get the game name
    game_name=$(grep -m 1 "name" "$game" | cut -d'"' -f4)
    if [ ! -L "$SHADERCACHE_PATH/$game_id" ] || [ ! -L "$COMPATDATA_PATH/$game_id" ]; then
        #check if compatdata folder exists
        if  [ -d "$COMPATDATA_PATH/$game_id" ] && [ ! -L "$COMPATDATA_PATH/$game_id" ]; then
                space+=$(du -sb "$COMPATDATA_PATH/$game_id" | cut -f1)
        fi
        if [ -d "$SHADERCACHE_PATH/$game_id" ] && [ ! -L "$SHADERCACHE_PATH/$game_id" ]; then
                space+=$(du -sb "$SHADERCACHE_PATH/$game_id" | cut -f1)
        fi
        spaceHuman=$(numfmt --to=iec-i --suffix=B --padding=7 $space)
        #Add the game to the array
        # if size is 0 then don't add it to the array
        if [ $space -ne 0 ]; then
            GAMES+=("FALSE" "$game_id" "$game_name" "$spaceHuman")
        fi
    fi
done

#zenity prompt user to choose the games cache to move
GAMES_CHOSEN=$(zenity --list --width=700 --height=500 --title="Select the games" --text="Choose the games you want to move the cache in the selected disk (They are all games installed on this same disk)" --column="Move?" --column="Appid" --column="Game" --column="Cache size" --checklist --print-column="2" "${GAMES[@]}" --separator=" ")
clear
# convert the string to an array
GAMES_CHOSEN=($GAMES_CHOSEN)
LOCAL_SPACE=$(df -BM --total "/home/deck" | grep total | awk '{print $4}' | sed 's/M//g')
#check if the user selected any games
if [ -z "$GAMES_CHOSEN" ]; then
    zenity --error --title="No games selected" --text="You didn't select any games."
    exit 1
else
    #declare toPrint
    (
    toPrint="[RESULTS]\n"
    #set gamepercent to 100 divided by the number of games
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
                #check if there is enough space on the sd card to move the cache
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