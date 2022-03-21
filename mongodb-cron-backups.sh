#!/bin/sh
#
# Tool to create MongoDB backups using CRON for scheduling
#
# Requirements: 
#  - mongodump from mongodb-database-tools
#      https://www.mongodb.com/try/download/database-tools
#  - env vars:
#    - add a file named "config" in the script folder (use the CONFIG.TEMPLATE to create one)

SCRIPTPATH=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPTPATH")
CONFIG="$BASEDIR/config"
# Load env vars from config
. $CONFIG 
 

USR="$MONGODB_USR"
PSWD="$MONGODB_PSWD"
CONNECTION="$MONGODB_CLUSTER"
DB_NAME="${MONGODB_DB_NAME:-"test"}"

OUTPUT_PATH="${CUSTOM_OUTPUT_PATH:-"/home/$USER/MONGODB_DUMP/"}"
URI="mongodb+srv://$USR:$PSWD@$CONNECTION/$DB_NAME"

# Create backup
# If backup size is zero, log error?
create_backup(){
  mkdir -p $OUTPUT_PATH && cd $OUTPUT_PATH
  echo "\n\e[1;33mCreating a backup with mongodump in $OUTPUT_PATH\e[0m\n" 
  mongodump --archive="$( date +%Y-%m-%d-%H-%M-%S )-$DB_NAME.archive" --uri=$URI
  echo "\n\e[1;33mDone\e[0m\n" 
}

# Delete old backups?
# Retain e.g. backups from last 7 days and delete rest

help(){
  printf \
    "This is the help file.\n"
  exit
}

case "$1" in
  "create")
    create_backup;;
  *)
    help;;
esac
