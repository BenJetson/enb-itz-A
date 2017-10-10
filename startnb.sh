#!/bin/bash

# For this to work, you need to have aliases for:
#     alias 'zim' should point to wherever Zim Wiki is on your system
#     alias 'cdenb' should cd to wherever the repository is stored

# meta
DEBUG=false

# check which platform we're on
OSTYPE=$(uname -s)

case "$OSTYPE" in 
    Linux*)     PLATFORM=1;;
    MINGW*)     PLATFORM=2;;
    *)          PLATFORM=0;;
esac 

# verify that environment is sane
CDENB_EXISTS=$(alias 'cdenb' 2>/dev/null)
ZIM_PATH_EXISTS=$(command -v zim 2>/dev/null)
ZIM_EXISTS=$(zim -v)

if [ $DEBUG = true ]; then 
    clear
    echo "OS-TYPE: " $OSTYPE
    echo "PLATFORM: " $PLATFORM
    echo "CDENB-EXISTS: " $CDENB_EXISTS
    echo "ZIM-EXISTS: " $ZIM_EXISTS
    echo "ZIM-PATH-EXISTS: " $ZIM_PATH_EXISTS
    clear
fi

# if platform unrecognized, then return to avoid breaking things
if [ $PLATFORM == 0 ]; then
    echo "ERROR: Unrecognized platform -- this script may be incompatible"
    return 1
fi

# if environment isn't sane, display errors

if [ -z "$CDENB_EXISTS" ]; then 
    echo "ERROR: Couldn't find alias to cd to notebook path."
    return 1
fi

if [ -z "$ZIM_PATH_EXISTS" ]; then
    echo "ERROR: Couldn't find Zim Wiki by alias 'zim' or your path variable."
    return 1
elif [ ! -z "$ZIM_EXISTS" ]; then
    echo "ERROR: Your path points to Zim Wiki, but no binary found!"
    return 1
fi


# cd into directory, and synchronize changes
cdenb
git checkout master
git pull
git push

# copy notebook template changes to system, if any
if [ $PLATFORM == 1 ]; then
    yes | cp -r ./templates ~/.local/share/zim/
elif [ $PLATFORM == 2 ]; then 
    yes | cp -r ./templates ~/AppData/Roaming/zim/data/zim/
fi

# open the notebook
zim ./notebook & disown

