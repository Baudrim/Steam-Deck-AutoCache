# Steam-Deck-AutoCache
# ⚠️ Warning, the script has not yet been tested in real conditions ! ⚠️

## Introduction
A small script that allows to automatically move the cache on the SD card but only the caches of the games installed on it which allows to save space on the internal storage without having the problem of not being able to launch the games by changing the SD card,  it is just necessary to restart the script when a new game is installed.

This will create a cache folder on the root of the sd card containing compatdata and shadercache.
Then detect the games on the sd card and move the cache related to these games to the sd card. A symbolic link is generated in the internal storage. And voila !


# Next upate
* TODO: Change the Game check to a more efficient way -> check the appmanifest file instead of the whole cache folder *
* TODO: Better text and color output *
* TODO: Check the size before asking for user confirmation *
* TODO: easier way to launch the script on the steam deck *
