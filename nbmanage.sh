#!/bin/bash

# For this to work, you need to have aliases for:
#     alias 'zim' should point to wherever Zim Wiki is on your system
#     alias 'cdenb' should cd to wherever the repository is stored

# useful functions
spacer() {
    for i in {1..1}
    do
        echo ""
    done
}

section() {
    spacer
    echo "---$1---"
}

cdto() {
    section "CD"
    if [ -z "$1" ]; then
        cdenb
    else
        cd $1
    fi
    echo $PWD
}

showhelp() {
cat <<-ENDHELP
NAME

    nbmanage - manages the ZIM engineering notebook

SYNOPSIS

    nbmanage [MODE] [OPITONS]

DESCRIPTION

    ==MODES==
    cd              Changes the current directory to the repo directory.

    cd-nb           Changes the current directory to the notebook directory.

    cd-rt           Changes the current directory to the repository ZIM
                    template directory.

    cd-st           Changes the current directory to the local system ZIM
                    template directory.

    envcheck        Runs a sanity check for notebook editing on your 
                    environment. Checks for aliases and necessary software. 

    explore         Opens a file browser to repo directory.

    run             Equivalent to running with no parameters. Performs an 
                    environment check, a full synchronization, and opens 
                    the notebook in ZIM (envcheck, sync, and view).

    sync            Runs a full VCS synchronization with the server, 
                    and then updates system ZIM templates from the repo.

    sync-repo       Runs a full VCS synchronization, with pull and push.

    sync-templates  Updates templates from the repo template directory  
                    to the system ZIM template directory.

    view            Opens the notebook in ZIM.

    ==OPTIONS==

    nocd            CD back to the origin directory when finished. Only
                    works with non-cd related modes. Otherwise, the script
                    will CD to the repository when executed by default.

    debug           Make the script print output useful for debugging.

ENDHELP
}

# globals
debug=false
nocd=false
origindir=$PWD
mode=-1

# check modes from first argument
if [ $# -gt 2 ]; then
    spacer
    echo "ERROR: Too many arguments."
    return 1 2>/dev/null; exit 1
elif [ $# -eq 0 ]; then
    mode=0
elif [ "$1" == "help" ]; then
    showhelp
    return 0 2>/dev/null; exit 
elif [ "$1" == "envcheck" ]; then
    mode=-1
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
elif [ "$1" == "cd" ]; then
    mode=5
elif [ "$1" == "cd-nb" ]; then
    mode=6
elif [ "$1" == "cd-rt" ]; then
    mode=7
elif [ "$1" == "cd-st" ]; then
    mode=8
elif [ "$1" == "explore" ]; then
    mode=9
    nocd=true
else
    spacer
    echo "ERROR: Illegal argument."
    echo "       First argument should be a valid mode, not '$1'."
    return 1 2>/dev/null; exit 1
fi

# enable debug output if requested
if [ $# -eq 2 ]; then
    if [ "$2" == "debug" ]; then
        debug=true
    elif [ $mode -ge 5 ] && [ $mode -le 8 ] && [ "$2" == "nocd" ]; then
        spacer
        echo "ERROR: Illegal argument."
        echo "       Option 'nocd' is incompatible with cd-related modes."
        return 1 2>/dev/null; exit 1
    elif [ "$2" == "nocd" ]; then
        nocd=true
    else
        spacer
        echo "ERROR: Illegal argument."
        echo "       Second argument should be valid option, not '$2'."
        return 1 2>/dev/null; exit 1
    fi
fi

section "CHECKING ENVIRONMENT"
# check which platform we're on
os_type=$(uname -s)

case "$os_type" in 
    Linux*) # LINUX
        platform=1
        template_path=~/.local/share/zim
        ;;
    MINGW*) # WINDOWS
        platform=2
        template_path=~/AppData/Roaming/zim/data/zim
        ;;
    *)
        platform=0
        template_path=""
        ;;
esac 

# verify that environment is sane
cdenb_exists=$(alias 'cdenb' 2>/dev/null)
zim_path_exists=$(command -v zim 2>/dev/null)
zim_exists=$(zim -v 2>&1 1>/dev/null)
# zim_exists=$(zim -v 1>/dev/null)

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
    echo "TEMPLATE-PATH: " $template_path
    spacer
fi

# if platform unrecognized, then return to avoid breaking things
if [ $platform == 0 ]; then
    spacer
    echo "ERROR: Unrecognized platform -- this script may be incompatible"
    return 1 2>/dev/null; exit 1
fi

# if environment isn't sane, display errors and exit

if [ -z "$cdenb_exists" ]; then 
    spacer
    echo "ERROR: Couldn't find alias to cd to notebook path."
    return 1 2>/dev/null; exit 1
fi

if [ -z "$zim_path_exists" ]; then
    spacer
    echo "ERROR: Couldn't find Zim Wiki by alias 'zim' or your path variable."
    return 1 2>/dev/null; exit 1
elif [ ! -z "$zim_exists" ]; then
    spacer
    echo "ERROR: Your path points to Zim Wiki, but no binary found!"
    return 1 2>/dev/null; exit 1
fi

echo "PASS - Environment is sane."

# cd into directory
if [ $mode -ne -1 ]; then
    cdto
fi

if [ $? -ne 0 ]; then
    spacer
    echo "ERROR: CD to repository failed!"
    return 1 2>/dev/null; exit 1
fi

# synchronize changes with server
if [ $mode -eq 0 ] || [ $mode -eq 1 ] || [ $mode -eq 2 ]; then
    section "CHECKOUT"
    git checkout master

    if [ $? -ne 0 ]; then
        spacer
        echo "ERROR: Git checkout failed!"
        return 1 2>/dev/null; exit 1
    fi

    section "PULL"
    git pull

    if [ $? -ne 0 ]; then
        spacer
        echo "ERROR: Git pull failed!"
        return 1 2>/dev/null; exit 1
    fi

    section "PUSH"
    git push

    if [ $? -ne 0 ]; then
        spacer
        echo "ERROR: Git push failed!"
        return 1 2>/dev/null; exit 1
    fi
fi

# copy notebook template changes to system, if any
if [ $mode -eq 0 ] || [ $mode -eq 1 ] || [ $mode -eq 3 ]; then
    section "COPY TEMPLATES"
    if [ -z "$template_path" ]; then
        spacer
        echo "ERROR: No known template path!"
        return 1 2>/dev/null; exit 1
    fi

    yes | cp -r ./templates/* $template_path/

    if [ $? -ne 0 ]; then
        spacer
        echo "ERROR: Copying templates failed!"
        return 1 2>/dev/null; exit 1
    fi

    echo "Success! Templates copied successfully."
fi

# open the notebook
if [ $mode -eq 0 ] || [ $mode -eq 4 ]; then
    section "OPEN NOTEBOOK"
    zim ./notebook & disown
    echo "Success!"
fi

# launch file browser to notebook if requested.
if [ $mode -eq 9 ]; then
    section "EXPLORE"
    case $platform in
        1) xdg-open .;;
        2) explorer .;;
    esac
fi


# cd to directory based on arguments
case $mode in
    6) cdto ./notebook;;
    7) cdto ./templates;;
    8) cdto $template_path;;
esac

if [ $nocd = true ]; then
    cdto $origindir
fi

if [ $? -ne 0 ]; then
        spacer
        echo "ERROR: CD failed!"
        return 1 2>/dev/null; exit 1
    fi

spacer
echo "Done."
