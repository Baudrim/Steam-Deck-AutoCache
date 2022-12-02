# Steam-Deck-AutoCache
# ⚠️ Warning, the script has not yet been tested in real conditions ! The script works for me but bugs are always possible, do not hesitate to send me feedback⚠️

# Introduction
A small script that allows to automatically move the cache on the SD card but only the caches of the games installed on it which allows to save space on the internal storage without having the problem of not being able to launch the games by changing the SD card,  it is just necessary to restart the script when a new game is installed.

This will create a cache folder on the root of the sd card containing compatdata and shadercache.
Then detect the games on the sd card and move the cache related to these games to the sd card. A symbolic link is generated in the internal storage. And voila !

# USAGE
![Peek 2022-12-02 04-56](https://user-images.githubusercontent.com/46636715/205211904-0893f26f-1cd0-4800-af8e-1932e3f17ec3.gif)
* Right click on the autoCache.sh file
* Click "Properties" -> Permissions -> check the "Is executable"
* Double-click the autoCache.sh file
* Select the drive where you want to move their corresponding game cache
* Select the game you want to move cache to the selected drive
* Wait, a result page will appear, you can close it whenever you want ! GG ! :)



# IF THE EXECUTABLES DOES NOT WORK YOU CAN TRY THIS WAY
* Right click on empty space where the script is
* Press "Open Terminal"
* Write this command: ``` bash ./autoCache.sh ```
* Now it will find all the game on the sd card and ask you if you want to move the cache of these game to the sd card by pressing Y or N

# MORE INFO
_Note that in some cases, the performance of the game can be reduced. That's why I will release soon on the same repo a "autoCache_uninstall.sh" which will allow you to move the cache of the games you want in the internal memory again_
