#!/bin/bash

# Check that script was run not as root or with sudo
if [ "$EUID" -eq 0 ]
  then echo "Please do not run this script as root or using sudo"
  exit
fi

# set -x

# See if we need to check GIT for updates
if [ -e .env ]; then
    # Check for Updated Docker-Compose
    printf "Checking for update to Docker-Compose (If needed - You will be prompted for SUDO credentials).\\n\\n"
    onlinever=`curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "tag_name" | cut -d ":" -f2 | sed 's/"//g' | sed 's/,//g' | sed 's/ //g'`
    printf "Current online version is: $onlinever\\n"
    localver=`docker-compose -v | cut -d " " -f3 | sed 's/,//g'`
    printf "Current local version is: $localver\\n"
    if [ $localver != $onlinever ]; then
        sudo curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "browser_download_url" | grep -m1 `uname -s`-`uname -m` | cut -d '"' -f4 | xargs sudo curl -L -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        printf "\\n\\n"
    else
        printf "No Docker-Compose Update needed.\\n\\n"
    fi
    # Stash any local changes to the base files
    git stash > /dev/null 2>&1
    printf "Updating your local copy of Mediabox.\\n\\n"
    # Pull the latest files from Git
    git pull
    # Check to see if this script "mediabox.sh" was updated and restart it if necessary
    changed_files="$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)"
    check_run() {
        echo "$changed_files" | grep --quiet "$1" && eval "$2"
    }
    # Provide a message once the Git check/update  is complete
    if [ -z "$changed_files" ]; then
        printf "Your Mediabox is current - No Update needed.\\n\\n"
    else
        printf "Mediabox Files Update complete.\\n\\nThis script will restart if necessary\\n\\n"
    fi
    # Rename the .env file so this check fails if mediabox.sh needs to re-launch
    mv .env 1.env
    read -r -p "Press any key to continue... " -n1 -s
    printf "\\n\\n"
    # Run exec mediabox.sh if mediabox.sh changed
    check_run mediabox.sh "exec ./mediabox.sh"
fi

# After update collect some current known variables
if [ -e 1.env ]; then
    # Grab the NBZGet usernames & passwords to reuse
    daemonun=$(grep CPDAEMONUN 1.env | cut -d = -f2)
    daemonpass=$(grep CPDAEMONPASS 1.env | cut -d = -f2)
    duckdnsdomain=$(grep DUCKDNSDOMAIN 1.env | cut -d = -f2)
    duckdnstoken=$(grep DUCKDNSTOKEN 1.env | cut -d = -f2)
    pmstag=$(grep PMSTAG 1.env | cut -d = -f2)
    dldirectory=$(grep DLDIR 1.env | cut -d = -f2)
    tvdirectory=$(grep TVDIR 1.env | cut -d = -f2)
    miscdirectory=$(grep MISCDIR 1.env | cut -d = -f2)
    moviedirectory=$(grep MOVIEDIR 1.env | cut -d = -f2)
    # Echo back the media directioies, and other info to see if changes are needed
    printf "These are the Media Directory paths currently configured.\\n"
    printf "Your DOWNLOAD Directory is: %s \\n" "$dldirectory"
    printf "Your TV Directory is: %s \\n" "$tvdirectory"
    printf "Your MISC Directory is: %s \\n" "$miscdirectory"
    printf "Your MOVIE Directory is: %s \\n" "$moviedirectory"
    printf "\\n\\n"
    read  -r -p "Are these directiores still correct? (y/n) " diranswer `echo \n`
    printf "\\n\\n"
    printf "Your PLEX Release Type is: %s" "$pmstag"
    printf "\\n\\n"
    read  -r -p "Do you need to change your PLEX Release Type? (y/n) " pmsanswer `echo \n`
    printf "\\n\\n"
    read  -r -p "Do you need to change your DuckDNS Credentials? (y/n) " duckdnsanswer `echo \n`
    # Now we need ".env" to exist again so we can stop just the Medaibox containers
    mv 1.env .env
    # Stop the current Mediabox stack
    printf "\\n\\nStopping Current Mediabox containers.\\n\\n"
    docker-compose stop
    # Make a datestampted copy of the existing .env file
    mv .env "$(date +"%Y-%m-%d_%H:%M").env"
fi

# Collect Server/User info:
# Get local Username
localuname=$(id -u -n)
# Get PUID
PUID=$(id -u "$localuname")
# Get GUID
PGID=$(id -g "$localuname")
# Get Docker Group Number
DOCKERGRP=$(grep docker /etc/group | cut -d ':' -f 3)
# Get Hostname
thishost=$(hostname)
# Get IP Address
locip=$(hostname -I | awk '{print $1}')
# Get Time Zone
time_zone=$(cat /etc/timezone)	
# Get CIDR Address
slash=$(ip a | grep "$locip" | cut -d ' ' -f6 | awk -F '/' '{print $2}')
lannet=$(awk -F"." '{print $1"."$2"."$3".0"}'<<<$locip)/$slash

# Get DuckDNS Info
if [ -z "$duckdnsanswer" ] || [ "$duckdnsanswer" == "y" ]; then
read -r -p "What is your DuckDNS subdomain?: " duckdnsdomain
read -r -p "What is your DuckDNS token?: " duckdnstoken
printf "\\n\\n"
fi

# Get info needed for PLEX Official image
if [ -z "$pmstag" ] || [ "$pmsanswer" == "y" ]; then
read -r -p "Which PLEX release do you want to run? By default 'public' will be used. (latest, public, plexpass): " pmstag
read -r -p "If you have PLEXPASS what is your Claim Token from https://www.plex.tv/claim/ (Optional): " pmstoken
fi
# If not set - set PMS Tag to Public:
if [ -z "$pmstag" ]; then
   pmstag=public
fi

# Ask user if they already have TV and Movie directories
if [ -z "$diranswer" ]; then
printf "\\n\\n"
printf "If you already have TV - Movie directories you want to use you can enter them next.\\n"
printf "If you want Mediabox to generate it's own directories just press enter to these questions."
printf "\\n\\n"
read -r -p "Where do you store your DOWNLOADS? (Please use full path - /path/to/downloads ): " dldirectory
read -r -p "Where do you store your TV media? (Please use full path - /path/to/tv ): " tvdirectory
read -r -p "Where do you store your MISC media? (Please use full path - /path/to/misc ): " miscdirectory
read -r -p "Where do you store your MOVIE media? (Please use full path - /path/to/movies ): " moviedirectory
fi
if [ "$diranswer" == "n" ]; then
read -r -p "Where do you store your DOWNLOADS? (Please use full path - /path/to/downloads ): " dldirectory
read -r -p "Where do you store your TV media? (Please use full path - /path/to/tv ): " tvdirectory
read -r -p "Where do you store your MISC media? (Please use full path - /path/to/misc ): " miscdirectory
read -r -p "Where do you store your MOVIE media? (Please use full path - /path/to/movies ): " moviedirectory
fi

# Create the directory structure
if [ -z "$dldirectory" ]; then
    mkdir -p content/completed
    mkdir -p content/incomplete
    dldirectory="$PWD/content"
else
  mkdir -p "$dldirectory"/completed
  mkdir -p "$dldirectory"/incomplete
fi
if [ -z "$tvdirectory" ]; then
    mkdir -p content/tv
    tvdirectory="$PWD/content/tv"
fi
if [ -z "$miscdirectory" ]; then
    mkdir -p content/misc
    miscdirectory="$PWD/content/misc"
fi
if [ -z "$moviedirectory" ]; then
    mkdir -p content/movies
    moviedirectory="$PWD/content/movies"
fi

mkdir -p duplicati
mkdir -p duplicati/backups
mkdir -p flaresolverr
mkdir -p glances
mkdir -p historical/env_files
mkdir -p jackett
mkdir -p muximux
mkdir -p nzbget
mkdir -p nzbhydra2
mkdir -p ombi
mkdir -p overseerr
mkdir -p "plex/Library/Application Support/Plex Media Server/Logs"
mkdir -p portainer
mkdir -p radarr
mkdir -p requestrr
mkdir -p sonarr
mkdir -p speedtest
mkdir -p tautulli
mkdir -p pihole
mkdir -p pihole/etc-pihole
mkdir -p pihole/etc-dnsmasq.d
mkdir -p samba

# Create the .env file
echo "Creating the .env file with the values we have gathered"
printf "\\n"
cat << EOF > .env
###  ------------------------------------------------
###  M E D I A B O X   C O N F I G   S E T T I N G S
###  ------------------------------------------------
###  The values configured here are applied during
###  $ docker-compose up
###  -----------------------------------------------
###  DOCKER-COMPOSE ENVIRONMENT VARIABLES BEGIN HERE
###  -----------------------------------------------
###
EOF
{
echo "LOCALUSER=$localuname"
echo "HOSTNAME=$thishost"
echo "IP_ADDRESS=$locip"
echo "PUID=$PUID"
echo "PGID=$PGID"
echo "DOCKERGRP=$DOCKERGRP"
echo "PWD=$PWD"
echo "DLDIR=$dldirectory"
echo "TVDIR=$tvdirectory"
echo "MISCDIR=$miscdirectory"
echo "MOVIEDIR=$moviedirectory"
echo "CIDR_ADDRESS=$lannet"
echo "TZ=$time_zone"
echo "PMSTAG=$pmstag"
echo "PMSTOKEN=$pmstoken"
echo "DUCKDNSDOMAIN=$duckdnsdomain"
echo "DUCKDNSTOKEN=$duckdnstoken"
} >> .env
echo ".env file creation complete"
printf "\\n\\n"

# Move back-up .env files
mv 20*.env historical/env_files/ > /dev/null 2>&1
mv historical/20*.env historical/env_files/ > /dev/null 2>&1

# # Set vm.max_map_count for elasticsearch
# sudo sed '/^vm.max_map_count=/{h;s/=.*/=262144/};${x;/^$/{s//vm.max_map_count=262144/;H};x}' /etc/sysctl.conf > /etc/sysctl.conf
# sudo sysctl -w vm.max_map_count=262144

# Configure the access to NZBGet's webui
if [ -z "$daemonun" ]; then
echo "You need to set a username and password for some of the programs - including."
echo "The NZBGet's API & web interface."
read -r -p "What would you like to use as the access username?: " daemonun
read -r -p "What would you like to use as the access password?: " daemonpass
printf "\\n\\n"
fi

# Push the NZBGet Access info to the .env file
{
echo "NZBGETUN=$daemonun"
echo "NZBGETPASS=$daemonpass"
echo "PIHOLEPASS=$daemonpass"
echo "SAMBAUN=$daemonun"
echo "SAMBAPASS=$daemonpass"
} >> .env

# Download & Launch the containers
echo "The containers will now be pulled and launched"
echo "This may take a while depending on your download speed"
read -r -p "Press any key to continue... " -n1 -s
printf "\\n\\n"
docker-compose up -d --remove-orphans
printf "\\n\\n"

# Finish up the config
printf "Configuring NZBGet, Muximux, and Permissions \\n"
printf "This may take a few minutes...\\n\\n"

# Configure FlareSolverr URL for Jackett
while [ ! -f jackett/Jackett/ServerConfig.json ]; do sleep 1; done
docker stop jackett > /dev/null 2>&1
perl -i -pe 's/"FlareSolverrUrl": ".*",/"FlareSolverrUrl": "http:\/\/'$locip':8191",/g' jackett/Jackett/ServerConfig.json
docker start jackett > /dev/null 2>&1

# Configure NZBGet
[ -d "content/nbzget" ] && mv content/nbzget/* content/ && rmdir content/nbzget
while [ ! -f nzbget/nzbget.conf ]; do sleep 1; done
docker stop nzbget > /dev/null 2>&1
perl -i -pe "s/ControlUsername=nzbget/ControlUsername=$daemonun/g"  nzbget/nzbget.conf
perl -i -pe "s/ControlPassword=tegbzn6789/ControlPassword=$daemonpass/g"  nzbget/nzbget.conf
perl -i -pe "s/{MainDir}\/intermediate/{MainDir}\/incomplete/g" nzbget/nzbget.conf
docker start nzbget > /dev/null 2>&1

# Configure Samba
docker stop samba > /dev/null 2>&1
perl -i -pe "s/daemonun/$daemonun/g" samba/config.yml
perl -i -pe "s/daemonpass/$daemonpass/g" samba/config.yml
perl -i -pe "s/puid/$PUID/g" samba/config.yml
perl -i -pe "s/pgid/$PGID/g" samba/config.yml
docker start samba > /dev/null 2>&1

# Configure Muximux settings and files
while [ ! -f muximux/www/muximux/settings.ini.php-example ]; do sleep 1; done
docker stop muximux > /dev/null 2>&1
cp settings.ini.php muximux/www/muximux/settings.ini.php
cp mediaboxconfig.php muximux/www/muximux/mediaboxconfig.php
sed '/^PIA/d' < .env > muximux/www/muximux/env.txt # Pull PIA creds from the displayed .env file
perl -i -pe "s/locip/$locip/g" muximux/www/muximux/settings.ini.php
perl -i -pe "s/locip/$locip/g" muximux/www/muximux/mediaboxconfig.php
perl -i -pe "s/daemonun/$daemonun/g" muximux/www/muximux/mediaboxconfig.php
perl -i -pe "s/daemonpass/$daemonpass/g" muximux/www/muximux/mediaboxconfig.php
docker start muximux > /dev/null 2>&1

# If PlexPy existed - copy plexpy.db to Tautulli
if [ -e plexpy/plexpy.db ]; then
    docker stop tautulli > /dev/null 2>&1
    mv tautulli/tautulli.db tautulli/tautulli.db.orig
    cp plexpy/plexpy.db tautulli/tautulli.db
    mv plexpy/plexpy.db plexpy/plexpy.db.moved
    docker start tautulli > /dev/null 2>&1
    mv plexpy/ historical/plexpy/
fi
if [ -e plexpy/plexpy.db.moved ]; then # Adjust for missed moves
    mv plexpy/ historical/plexpy/
fi

# Completion Message
printf "Setup Complete - Open a browser and go to: \\n\\n"
printf "http://%s \\nOR http://%s If you have appropriate DNS configured.\\n\\n" "$locip" "$thishost"
printf "Start with the MEDIABOX Icon for settings and configuration info.\\n"
