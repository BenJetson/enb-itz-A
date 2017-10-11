#!/bin/bash

# For this to work, you need to have aliases for:
#     alias 'zim' should point to wherever Zim Wiki is on your system
#     alias 'cdenb' should cd to wherever the repository is stored

# meta
debug=false

spacer () {
    for i in {1..1}
    do
        echo ""
    done
}

section () {
    spacer
    echo "---$1---"
}

section "CHECKING ENVIRONMENT"
# check which platform we're on
os_type=$(uname -s)

case "$os_type" in 
    Linux*)     platform=1;;
    MINGW*)     platform=2;;
    *)          platform=0;;
esac 

# verify that environment is sane
cdenb_exists=$(alias 'cdenb' 2>/dev/null)
zim_path_exists=$(command -v zim 2>/dev/null)
zim_exists=$(zim -v 1>/dev/null)

if [ $debug = true ]; then 
    spacer
    echo "OS-TYPE: " $os_type
    echo "platform: " $platform
    echo "CDENB-EXISTS: " $cdenb_exists
    echo "ZIM-EXISTS: " $zim_exists
    echo "ZIM-PATH-EXISTS: " $zim_path_exists
    spacer
fi

# if platform unrecognized, then return to avoid breaking things
if [ $platform == 0 ]; then
    echo "ERROR: Unrecognized platform -- this script may be incompatible"
    return 1
fi

# if environment isn't sane, display errors

if [ -z "$cdenb_exists" ]; then 
    echo "ERROR: Couldn't find alias to cd to notebook path."
    return 1
fi

if [ -z "$zim_path_exists" ]; then
    echo "ERROR: Couldn't find Zim Wiki by alias 'zim' or your path variable."
    return 1
elif [ ! -z "$zim_exists" ]; then
    echo "ERROR: Your path points to Zim Wiki, but no binary found!"
    return 1
fi

echo "PASS - Environment is sane."

# cd into directory, and synchronize changes
section "CD"
cdenb
echo $PWD
section "CHECKOUT"
git checkout master
section "PULL"
git pull
section "PUSH"
git push

# copy notebook template changes to system, if any
section "COPY TEMPLATES"
if [ $platform == 1 ]; then
    (
        set -e
        yes | cp -r ./temAAKplates ~/.local/share/zim/
    )
elif [ $platform == 2 ]; then 
    yes | cp -r ./templates ~/AppData/Roaming/zim/data/zim/
fi

# open the notebook
section "OPEN NOTEBOOK"
zim ./notebook & disown
echo "Success!"

