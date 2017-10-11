#!/bin/bash

# set -o errexit

# For this to work, you need to have aliases for:
#     alias 'zim' should point to wherever Zim Wiki is on your system
#     alias 'cdenb' should cd to wherever the repository is stored

# useful functions
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

# globals
debug=false
mode=-1

# check modes from first argument
if [ $# -gt 2 ]; then
    spacer
    echo "ERROR: Too many arguments."
    return 1
elif [ $# -eq 0 ]; then
    mode=0
elif [ "$1" == "run" ]; then
    mode=0
elif [ "$1" == "sync" ]; then
    mode=1
elif [ "$1" == "sync-repo" ]; then
    mode=2
elif [ "$1" == "sync-templates" ]; then
    mode=3
elif [ "$1" == "view" ]; then
    mode=4
else
    spacer
    echo "ERROR: Illegal argument."
    echo "       First argument should be a valid mode, not '$1'."
    return 1
fi

# enable debug output if requested
if [ $# -eq 2 ]; then
    if [ "$2" == "debug" ]; then
        debug=true
    else
        spacer
        echo "ERROR: Illegal argument."
        echo "       Second argument should be debug switch, not '$2'."
        return 1
    fi
fi

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
    section "DEBUGGING"
    echo "DEBUG-MODE: " $debug
    echo "NUM-ARGS: " $#
    echo "ARG1: " $1
    echo "ARG2: " $2
    echo "SCRIPT-MODE: " $mode
    echo "OS-TYPE: " $os_type
    echo "PLATFORM: " $platform
    echo "CDENB-EXISTS: " $cdenb_exists
    echo "ZIM-EXISTS: " $zim_exists
    echo "ZIM-PATH-EXISTS: " $zim_path_exists
    spacer
fi

# if platform unrecognized, then return to avoid breaking things
if [ $platform == 0 ]; then
    spacer
    echo "ERROR: Unrecognized platform -- this script may be incompatible"
    return 1
fi

# if environment isn't sane, display errors and exit

if [ -z "$cdenb_exists" ]; then 
    spacer
    echo "ERROR: Couldn't find alias to cd to notebook path."
    return 1
fi

if [ -z "$zim_path_exists" ]; then
    spacer
    echo "ERROR: Couldn't find Zim Wiki by alias 'zim' or your path variable."
    return 1
elif [ ! -z "$zim_exists" ]; then
    spacer
    echo "ERROR: Your path points to Zim Wiki, but no binary found!"
    return 1
fi

echo "PASS - Environment is sane."

# cd into directory
section "CD"
cdenb
echo $PWD

# synchronize changes with server
if [ $mode -eq 0 ] || [ $mode -eq 1 ] || [ $mode -eq 2 ]; then
    section "CHECKOUT"
    git checkout master

    section "PULL"
    git pull

    section "PUSH"
    git push
fi

# copy notebook template changes to system, if any
if [ $mode -eq 0 ] || [ $mode -eq 1 ] || [ $mode -eq 3 ]; then
    section "COPY TEMPLATES"
    if [ $platform == 1 ]; then
         template_path=~/.local/share/zim/
    elif [ $platform == 2 ]; then 
        template_path=~/AppData/Roaming/zim/data/zim/
    else
        spacer
        echo "ERROR: No known template path!"
        return 1
    fi

    yes | cp -r ./templates $template_path

    if [ $? -ne 0 ]; then
        spacer
        echo "ERROR: Copying templates failed!"
        return 1
    fi

    echo "Success! Templates copied to $template_path."

fi

# open the notebook
if [ $mode -eq 0 ] || [ $mode -eq 4 ]; then
    section "OPEN NOTEBOOK"
    # zim ./notebook & disown
    echo "Success!"
fi

spacer
echo "Done."

