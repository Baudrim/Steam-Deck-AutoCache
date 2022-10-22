# A script to automatically move the cache of the steam deck on the sd card only of the game installed on the sd card

# The path to the cache folder
COMPATDATA_PATH="/home/deck/.steam/steam/steamapps/compatdata"
SHADERCACHE_PATH="/home/deck/.steam/steam/steamapps/shadercache"

# The path to the sd card and game path
SD_PATH="/run/media/"
# get the first folder in media, supposed to be the sd card
SD_PATH=$(ls -d $SD_PATH*/ | head -n 1)
GAME_PATH="$SD_PATH/steamapps/common"
STEAMAPPS_PATH="$SD_PATH/steamapps/"

# Steam api url
STEAMAPI_URL="https://api.steampowered.com/ISteamApps/GetAppList/v2/"

#font color
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

declare -i mode=0
declare -i space=0
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

#We move the cache to the sd card if the game is on this sd card by finding the game in the steam api with the game id
for game in "$COMPATDATA_PATH"/*; do
	mode=0
	space=0
	game_id=$(basename "$game")
	game_name=$(curl -s "$STEAMAPI_URL" | jq -r ".applist.apps[] | select(.appid == $game_id) | .name")
	
	if [ ! "$game_name" = "" ]; then
			#check if the game is installed on the sd card by looking if the id of the game is in the steamapps folder with the name appmanifest_gameid.acf
			if [ -f "$STEAMAPPS_PATH/appmanifest_$game_id.acf" ]; then
			echo "Game $game_name seem to be on the sd card."
			# check if the game cache is already on the sd card if not move it then create a symbolic link
			if [ ! -d "$SD_PATH/cache/compatdata/$game_id" ]; then
				echo -e $GREEN "The compatdata of $game_name can be moved to the sd card" $NC
					mode+=1
					space+=$(du -s "$game" | cut -f1)
			else
				echo -e $ORANGE "The compatdata of $game_name is already on the sd card" $NC
			fi			
			if [ ! -d "$SD_PATH/cache/shadercache/$game_id" ]; then
				echo -e $GREEN "The shadercache of $game_name can be moved to the sd card" $NC
				mode+=2
				space+=$(du -s "$SHADERCACHE_PATH/$game_id" | cut -f1)
			else
				echo -e $ORANGE "The shadercache of $game_name is already on the sd card" $NC
			fi
			#ask user if he wants to move the cache to the sd card by pressing y or n
			if [ $mode -gt 0 ]; then
				echo -e $ORANGE "The cache of $game_name will take $space KB on the sd card" $NC
				read -p "Do you want to move the cache of $game_name to the sd card? (y/n) " -n 1 -r
				echo
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					case $mode in
					#check if the sd card has enough space to move the cache 
					1)
						if [ $(df -k "$SD_PATH" | awk 'NR==2 {print $4}') -gt $space ]; then
							mv "$game" "$SD_PATH/cache/compatdata"
							ln -s "$SD_PATH/cache/compatdata/$game_id" "$COMPATDATA_PATH"
						else
							echo -e $RED "Not enough space on the sd card to move the compatdata of $game_name" $NC
						fi
						;;
					2)
						if [ $(df -k "$SD_PATH" | awk 'NR==2 {print $4}') -gt $space ]; then
							mv "$SHADERCACHE_PATH/$game_id" "$SD_PATH/cache/shadercache"
							ln -s "$SD_PATH/cache/shadercache/$game_id" "$SHADERCACHE_PATH"
						else
							echo -e $RED "Not enough space on the sd card to move the shadercache of $game_name" $NC
						fi
						;;
					3)
						if [ $(df -k "$SD_PATH" | awk 'NR==2 {print $4}') -gt $space ]; then
							mv "$game" "$SD_PATH/cache/compatdata"
							ln -s "$SD_PATH/cache/compatdata/$game_id" "$COMPATDATA_PATH"
							mv "$SHADERCACHE_PATH/$game_id" "$SD_PATH/cache/shadercache"
							ln -s "$SD_PATH/cache/shadercache/$game_id" "$SHADERCACHE_PATH"
						else
							echo -e $RED "Not enough space on the sd card to move the compatdata and shadercache of $game_name" $NC
						fi
						;;
					esac
				fi
			fi
		else
			echo -e $ORANGE "$game_id have the name $game_name but does not seem to be on the sd card" $NC
		fi
	else
		echo -e $RED "Game ID $game_id not found in the steam api \n" $NC
	fi
	
	echo -e "\n"

done

# {"appid":2090220,"name":"OneHanded"}, {"appid":2090300,"name":"Grim Survivor"}, {"appid":1172470, "name":"Apex"}
