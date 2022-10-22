# A script to automatically move the cache of the steam deck on the sd card only of the game installed on the sd card

#TODO: Better text and color output
#TODO: easier way to launch the script on the steam deck

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
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# for game as appmanifest_*.acf
for game in "$STEAMAPPS_PATH"/appmanifest_*.acf; do
	mode=0
	space=0
	# get the game id
	game_id=$(basename "$game" | cut -d'_' -f2 | cut -d'.' -f1)
	# get the game name
	game_name=$(curl -s "$STEAMAPI_URL" | jq -r ".applist.apps[] | select(.appid == $game_id) | .name")
	# check if the compatdata and/or shadercache folder is already on the sd card
	if [ ! -d "$SD_PATH/cache/compatdata/$game_id" ]; then
		mode+=1
		space+=$(du -sb "$COMPATDATA_PATH/$game_id" | cut -f1)
	fi
	if [ ! -d "$SD_PATH/cache/shadercache/$game_id" ]; then
		mode+=2
		space+=$(du -sb "$SHADERCACHE_PATH/$game_id" | cut -f1)
	fi
	#convert byte  size in human readable format
	spacemb=$(numfmt --to=iec-i --suffix=B  $space)
	# check if the game actually exist in the compatdata folder and shadercache folder
	echo -e $NC "The game $game_name is installed on the sd card - Game ID: $game_id" $NC
	# check if cache exist in the internal storage
	if [ -d "$SHADERCACHE_PATH/$game_id" ] && [ -d "$COMPATDATA_PATH/$game_id" ]; then
		# check is the cache is already a symlink in case where user already made the symlink before and somewhere else
		if [ -L "$SHADERCACHE_PATH/$game_id" ] && [ ! -d $SD_PATH/cache/shadercache/$game_id ]; then
			echo -e $ORANGE "The shadercache of the game $game_name already has a symlink somewhere else..." $NC
		elif [ -L "$COMPATDATA_PATH/$game_id" ] && [ ! -d $SD_PATH/cache/compatdata/$game_id ]; then
			echo -e $ORANGE "The compatdata of the game $game_name already has a symlink somewhere else..." $NC
		else
			# if mode is 0 then the cache is already on the sd card
			if [ $mode -eq 0 ]; then
				echo -e $BLUE "The cache of $game_name is already on the sd card" $NC
			else
			# check if there is enough space on the sd card
				if [ $space -lt $(df -B1 $SD_PATH | tail -n 1 | awk '{print $4}') ]; then
					# ask user if he wants to move the cache to the sd card by pressing y or n
					echo -e $ORANGE "The cache of $game_name will take $spacemb on the sd card" $NC
					read -p "Do you want to move the cache of $game_name to the sd card? (y/n) " -n 1 -r
					echo
					if [[ $REPLY =~ ^[Yy]$ ]]; then
						case $mode in
						# check if the sd card has enough space to move the cache 
						1)
							mv "$COMPATDATA_PATH/$game_id" "$SD_PATH/cache/compatdata/"
							ln -s "$SD_PATH/cache/compatdata/$game_id" "$COMPATDATA_PATH"
							echo -e $GREEN "The compatdata of $game_name has been moved to the sd card" $NC
							;;
						2)
							mv "$SHADERCACHE_PATH/$game_id" "$SD_PATH/cache/shadercache/"
							ln -s "$SD_PATH/cache/shadercache/$game_id" "$SHADERCACHE_PATH"
							echo -e $GREEN "The shadercache of $game_name has been moved to the sd card" $NC
							;;
						3)
							
							mv "$COMPATDATA_PATH/$game_id" "$SD_PATH/cache/compatdata/"
							ln -s "$SD_PATH/cache/compatdata/$game_id" "$COMPATDATA_PATH"
							mv "$SHADERCACHE_PATH/$game_id" "$SD_PATH/cache/shadercache/"
							ln -s "$SD_PATH/cache/shadercache/$game_id" "$SHADERCACHE_PATH"
							echo -e $GREEN "The compatdata and shadercache of $game_name has been moved to the sd card" $NC
							;;
						esac
					fi
				else
					echo -e $RED "Not enough space on the sd card to move the cache $game_name need $spacemb" $NC
				fi
			fi
		fi
	else
		echo -e $PURPLE "$game_name is installed on the sd card but does not seem to have cache..." $NC
	fi
	echo -e "\n"
done 

# {"appid":2090220,"name":"OneHanded"}, {"appid":2090300,"name":"Grim Survivor"}, {"appid":1172470, "name":"Apex"}

