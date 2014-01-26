#!/bin/bash

echo -n "Cleaning out old playlists..."
rm playlists/*
echo "done"

echo "Extracting new playlists..."
java  -Xms32m -Xmx2048m -jar itunesexport.jar -outputDir="./playlists" -fileTypes=ALL -excludePlaylist="Recent Adds" -library="$HOME/Music/iTunes/iTunes Library.xml"
echo "done"
