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
create_backup(){
  mkdir -p $OUTPUT_PATH && cd $OUTPUT_PATH
  START_MESSAGE="Creating a backup of $CONNECTION using mongodump in $OUTPUT_PATH"
  echo "\n${pbold}$START_MESSAGE${pclear}"
  logger $START_MESSAGE

  START=$(date +%s)
  TOTAL_SIZE="0"

  # Loop through DBs to backup
  for db in $DB_NAMES; do
    echo "\n${pbold}Backing up $db...${pclear}"
    
    URI="mongodb+srv://$USR:$PSWD@$CONNECTION/$db"
    FILENAME="$( date +%Y-%m-%d-%H-%M-%S ).$db.archive.gz"
    mongodump --archive=$FILENAME --gzip --uri=$URI

    SIZE=$(stat --printf="%s" "$FILENAME") 
    TOTAL_SIZE=$(( $TOTAL_SIZE + $SIZE))
    if [ $SIZE -gt "0" ]; then
      echo "\n > Created $FILENAME, size $SIZE B"
    else
      # If backup size is zero, log error
      ERROR_MESSAGE="Possible problem: $FILENAME size was zero $SIZE B)"
      logger -s $ERROR_MESSAGE
    fi
  done

  END=$(date +%s)
  TIME=$(($END - $START))
  
  END_MESSAGE="Backups created for $CONNECTION (took "$TIME" s, total size $TOTAL_SIZE B)"
  printf "\n${pbold}$END_MESSAGE${pclear}\n\n"
  logger $END_MESSAGE
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
