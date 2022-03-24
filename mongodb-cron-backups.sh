#!/bin/sh
#
# Tool to create MongoDB backups using CRON for scheduling
#

# Styling
punderline="\e[4m"
pbold="\e[1m"
pboldcolor="\e[1;33m"
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
  echo "\n${pboldcolor}$START_MESSAGE${pclear}"
  logger $START_MESSAGE

  START=$(date +%s)
  TOTAL_SIZE="0"

  # Loop through DBs to backup
  for db in $DB_NAMES; do
    echo "\n${pboldcolor}Backing up $db...${pclear}"
    
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
  printf "\n${pboldcolor}$END_MESSAGE${pclear}\n\n"
  logger $END_MESSAGE
}

# Delete old backups
# Retain e.g. backups from last X (default: 7) days and delete rest
delete_old_backups(){
  cd $OUTPUT_PATH
  find -ctime +"${RETAIN_LAST_X_DAYS_BACKUPS:-"7"}" -delete
  DEL_MESSAGE="Backups older than "${RETAIN_LAST_X_DAYS_BACKUPS:-"7"}" days deleted for $CONNECTION."
  printf "\n${pboldcolor}$DEL_MESSAGE${pclear}\n\n"
  logger $DEL_MESSAGE
}

create_and_delete(){
  create_backup
  delete_old_backups
}

help(){
  printf \
"
${pboldcolor}Tool to create MongoDB backups from your MongoDB Atlas database through commandline allowing
CRON scheduling.${pclear}

${punderline}Requirements${pclear}
    ${pbold}mongodump${pclear} (from mongodb-database-tools)
        - Get a copy at https://www.mongodb.com/try/download/database-tools

    ${pbold}environment variables${pclear}
        - Add a file named 'config' in the same folder with the script
        - You can use the example_config to create the config.

${punderline}Commands${pclear}
Run ${pbold}mongobackup [action]${pclear} (or whatever name you specified instead of 'mongobackup' when creating the symlink to your \$PATH). 

  ${pbold}create${pclear}
      Creates backups for the databases defined in the config file.

  ${pbold}delete${pclear}
      Delete backups older than X days (as specified in the config file; defaults to 7, if not set).

  ${pbold}createdelete${pclear}
      Run the two above commands in sequence.

  ${pbold}help${pclear}
      Display this help file.
\n"
  exit
}

case "$1" in
  "create")
    create_backup;;
  "delete")
    delete_old_backups;;
  "createdelete")
    create_and_delete;;
  *)
    help;;
esac
