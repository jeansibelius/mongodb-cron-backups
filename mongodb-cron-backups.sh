#!/bin/sh
#
# Tool to create MongoDB backups using CRON for scheduling
#

# Styling
pbold="\e[1;33m"
pclear="\e[0m"

SCRIPTPATH=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPTPATH")
CONFIG="$BASEDIR/config"
# Load env vars from config
. $CONFIG 
 
USR="$MONGODB_USR"
PSWD="$MONGODB_PASSWORD"
CONNECTION="$MONGODB_CLUSTER"
DB_NAMES="$MONGODB_DB_NAMES"
OUTPUT_PATH="${CUSTOM_OUTPUT_PATH:-"/home/$USER/MONGODB_DUMP/"}"

# Create backup
# If backup size is zero, log error?
create_backup(){
  mkdir -p $OUTPUT_PATH && cd $OUTPUT_PATH
  echo "\n${pbold}Creating a backup of $CONNECTION using mongodump in $OUTPUT_PATH${pclear}\n" 

  START=$(date +%s)

  # Loop through DBs to backup
  for db in $DB_NAMES; do
    echo "${pbold}Backing up $db...${pclear}"
    URI="mongodb+srv://$USR:$PSWD@$CONNECTION/$db"
    mongodump --archive="$( date +%Y-%m-%d-%H-%M-%S ).$db" --uri=$URI
    echo
  done

  END=$(date +%s)
  TIME=$(($END - $START))
  
  printf "\n${pbold}Done${pclear} ("$TIME" s)\n" 
}

# Delete old backups?
# Retain e.g. backups from last 7 days and delete rest

help(){
  printf \
"
${pbold}Tool to create MongoDB backups from your MongoDB Atlas database through commandline allowing
CRON scheduling.${pclear}

Requirements: 
    - mongodump from mongodb-database-tools
        - Get a copy at https://www.mongodb.com/try/download/database-tools
    - env vars:
        - add a file named 'config' in the script folder (use the example_config to create one)
\n"
  exit
}

case "$1" in
  "create")
    create_backup;;
  *)
    help;;
esac
