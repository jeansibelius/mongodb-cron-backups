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
OUTPUT_PATH="$LOCAL_OUTPUT_PATH"

# Options for cron scheduling
CRONCMD="${SCRIPTPATH} create_and_delete > ${BASEDIR}/mongobackup.log 2>&1"
CRONSCHEDULE="${CRON_SCHEDULE:-"0 0 * * *"}"
CRONJOB="$CRONSCHEDULE $CRONCMD"

DAYS_TO_RETAIN="${RETAIN_LAST_X_DAYS_BACKUPS:-"7"}"

# Create backup
create_backup(){
  if [ ${#OUTPUT_PATH} -lt 1 ]; then
    echo "LOCAL_OUTPUT_PATH string length was less than 1. Please check that you have a valid path defined."
    exit 1
  fi
  mkdir -p $OUTPUT_PATH && cd $OUTPUT_PATH || ( echo "ERROR: Failed to created directory." && exit 1 )
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
  echo "\n${pboldcolor}Deleting backups older than $DAYS_TO_RETAIN days in $OUTPUT_PATH${pclear}\n"
  TOTAL_BACKUPS="0"
  if [ $OUTPUT_PATH = $PWD ]; then
    for db in $DB_NAMES; do
      filename="${db}.archive.gz"
      echo "Looking for files ending in .$filename..."
      temp_file=$(mktemp)
      find $OUTPUT_PATH -name "*.${filename}" -type f -ctime "$DAYS_TO_RETAIN" -print > $temp_file
      lines=$(cat $temp_file | wc -l)
      TOTAL_BACKUPS=$(( $TOTAL_BACKUPS + $lines))
      if [ $lines -gt "0" ]; then
        echo "Found $(cat $temp_file | wc -l) file(s). Deleting..."
        cat $temp_file && cat $temp_file | xargs -r rm --
        echo "Done.\n"
      else
        echo "No files found.\n"
      fi
      rm $temp_file
    done
    DEL_MESSAGE="Total of $TOTAL_BACKUPS backups older than $DAYS_TO_RETAIN days deleted for $CONNECTION."
    printf "${pboldcolor}$DEL_MESSAGE${pclear}\n\n"
    logger $DEL_MESSAGE
  else
    echo "Wrong directory $PWD"
  fi
}

create_and_delete(){
  create_backup
  delete_old_backups
}

add_to_cron(){
  ( crontab -l | grep -v -F "$CRONCMD" ; echo "$CRONJOB" ) | crontab -
  printf "Added $SCRIPTPATH to crontab.\n"
}

remove_from_cron(){
  ( crontab -l | grep -v -F "$CRONCMD" ) | crontab -
  printf "Removed $SCRIPTPATH from crontab.\n"
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

  ${pbold}create_and_delete${pclear}
      Run the two above commands in sequence.

  ${pbold}add_to_cron${pclear}
      Add the script to the current users crontab (using either the CRON_SCHEDULE from config or default daily at midnight).

      Can also be re-run in order to update the schedule of the an existing cron job added by the same command.

  ${pbold}remove_from_cron${pclear}
      Removes the script from crontab as added by add_to_cron.

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
  "create_and_delete")
    create_and_delete;;
  "add_to_cron")
    add_to_cron;;
  "remove_from_cron")
    remove_from_cron;;
  *)
    help;;
esac
