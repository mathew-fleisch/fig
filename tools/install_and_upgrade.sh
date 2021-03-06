#!/usr/bin/env bash

# This is the fig installation script. It runs just after you sign in for the first time

# Replace TAG_NAME with the commit hash, git tag (like v1.0.25), or leave empty
# This script should be run via curl:
#   sh <(curl -fsSL https://raw.githubusercontent.com/withfig/fig/main/tools/install_and_upgrade.sh) TAG_NAME
# or via wget:
#   sh <(wget -qO- https://raw.githubusercontent.com/withfig/fig/main/tools/install_and_upgrade.sh) TAG_NAME
# or via fetch:
#   sh <(fetch -o - https://raw.githubusercontent.com/withfig/fig/main/tools/install_and_upgrade.sh) TAG_NAME



FIGREPO='https://github.com/withfig/fig.git'

# We are constantly pushing changes to the public repo
# Each version of the swift app is only compatible with a certain version of the public repo
# The commit hash is passed in as a parameter to this script
# We hard reset to this commit hash
# If we don't get a hash, we just hard reset to the most recent version of the repo...
FIG_TAG="main"
[  -z "$1" ] || FIG_TAG=$1

echo Tag is $FIG_TAG


## Checks whether a command exists (like git)
command_exists() {
    command -v "$@" >/dev/null 2>&1
}

error() {
    echo "Error: $@" >&2
    exit 1
}


# Install fig. Override if already exists
install_fig() {

    # Create fig dir an cd into it
    mkdir -p ~/.fig
    cd ~/.fig


    # OLD GIT INSTALLATION - SEEMED TO BE ERRORS ON THE FETCH....
    # Initialise git repo. Doesn't matter if git repo already exists
    # git init

    # Create remote for origin if it doesn't already exist
    # git remote set-url origin $FIGREPO || git remote add origin $FIGREPO


    # Fetch most up to date version of withfig/fig repo
    # git fetch --all || error "git fetch failed"

    # Reset Fig fig back to a specific commit hash
    # git reset --hard $FIG_TAG || error "git reset failed"


    # Delete all untracked files from the repo
    # Note: this doesn't delete empty folders. Git tracks files and therefore assumes an empty folder does not exist
    # git clean -f -d || error "git clean failed"


    {
    curl https://codeload.github.com/withfig/fig/tar.gz/$FIG_TAG | \
        tar -xz --strip-components=1
    } || {
        echo downloading from main instead of fig tag_name && 
        curl https://codeload.github.com/withfig/fig/tar.gz/main | \
            tar -xz --strip-components=1
    } || {
        error "pulling withfig/fig repo failed"
    }

    mkdir -p ~/.fig/autocomplete;
    cd ~/.fig/autocomplete

    {
        curl https://codeload.github.com/withfig/autocomplete/tar.gz/master | \
        tar -xz --strip-components=2
    } || {
        error "pulling latest autocomplete files failed"
    }


    # Make files and folders that the user can edit (that aren't overridden by above)
    mkdir -p ~/.fig/user/aliases
    mkdir -p ~/.fig/user/apps
    mkdir -p ~/.fig/user/autocomplete
    mkdir -p ~/.fig/user/aliases

    touch ~/.fig/user/aliases/_myaliases.sh

    # Figpath definition
    touch ~/.fig/user/figpath.sh
    
    # Old
    # FIG_FIGPATH='export FIGPATH="~/.fig/apps:~/.fig/user/apps:~/run:"'
    # grep -q "$FIG_FIGPATH" ~/.fig/user/figpath.sh || echo "$FIG_FIGPATH"$'\n'"$(cat ~/.fig/user/figpath.sh)" > ~/.fig/user/figpath.sh


    # Define the figpath variable in the figpath file
    # The file should look like this:
    #   export FIGPATH="~/.fig/bin:~/run:"
    #   FIGPATH=$FIGPATH'~/abc/de fg/hi''~/zyx/wvut'

    grep -q 'FIGPATH=$FIGPATH' ~/.fig/user/figpath.sh || echo $'\n''FIGPATH=$FIGPATH' >> ~/.fig/user/figpath.sh

}


# Add the fig.sh to your profiles so it can be sourced on new terminal window load
append_to_profiles() {

    OLDSOURCEVAR='[ -s ~/.fig/exports/env.sh ] && source ~/.fig/exports/env.sh'
    FIG_SOURCEVAR='[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh'
    FIG_FULLSOURCEVAR=$'\n\n#### FIG ENV VARIABLES ####\n'$FIG_SOURCEVAR$'\n#### END FIG ENV VARIABLES ####\n\n'
    

    
    # Replace old sourcing in profiles 
    [ -e ~/.profile ] && sed -i '' 's/~\/.fig\/exports\/env.sh/~\/.fig\/fig.sh/g' ~/.profile
    [ -e ~/.zprofile ] && sed -i '' 's/~\/.fig\/exports\/env.sh/~\/.fig\/fig.sh/g' ~/.zprofile
    [ -e ~/.bash_profile ] && sed -i '' 's/~\/.fig\/exports\/env.sh/~\/.fig\/fig.sh/g' ~/.bash_profile

    
    # Check that new sourcing exists. If it doesn't, add it
    grep -q 'source ~/.fig/fig.sh' ~/.profile || echo "$FIG_FULLSOURCEVAR" >> ~/.profile
    grep -q 'source ~/.fig/fig.sh' ~/.zprofile || echo "$FIG_FULLSOURCEVAR" >> ~/.zprofile
    grep -q 'source ~/.fig/fig.sh' ~/.bash_profile || echo "$FIG_FULLSOURCEVAR" >> ~/.bash_profile
}



setup_welcome() {
    mkdir -p ~/run/;

    # Note: this gives 3 seconds to the curl request otherwise it just continues
    [ -s ~/run/welcome.run ] || curl https://app.withfig.com/welcome/welcome.run --output ~/run/welcome.run --silent --max-time 3 || true
}


main() {

    command_exists git || error "git is not installed"

    install_fig
    append_to_profiles
    setup_welcome

    echo success
    exit 0

}

main
