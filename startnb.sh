#!/bin/bash

# For this to work, you need to have aliases for:
#     alias 'zim' should point to wherever Zim Wiki is on your system
#     alias 'cdenb' should cd to wherever the repository is stored


# check which platform we're on
OSTYPE=$(uname -s)
echo $OSTYPE

case "$OSTYPE" in 
    Linux*)     PLATFORM=1;;
    MINGW*)     PLATFORM=2;;
    *)          PLATFORM=0;;
esac 
echo $PLATFORM

# if platform unrecognized, then exit to avoid breaking things
if [ $PLATFORM == 0 ]; then
    echo "ERROR: Unrecognized platform -- this script may be incompatible"
    exit 1
fi

# cd into directory, and synchronize changes
cdenb
git checkout master
git pull
git push

# copy notebook template changes to system, if any
if [ $PLATFORM == 1 ]; then
    yes | cp ./templates ~/.local/share/zim/
elif [ $PLATFORM == 2 ]; then 
    yes | cp ./templates ~/AppData/Roaming/zim/data/zim/
fi

# open the notebook
zim ~/Documents/GitHub/enb-itz-A/notebook

