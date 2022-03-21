# MongoDB Atlas backups

Tool to create MongoDB backups from your MongoDB Atlas database through commandline allowing CRON scheduling.

## Installation

1. Clone the repository to a location of your choosing.
2. Create a symlink in a folder included in your PATH (e.g. bin) for easing running of the script:
    1. `ln -s <PATH_TO_SCRIPT> /home/$USER/bin/mongobackup`
3. Copy the `example_config` to a file called `config` (keeping it in the same folder with the
   script) and edit your MongoDB Atlas details in. Be
   careful not to commit your private details to any repository.

## Requirements 
- `mongodump` from [mongodb-database-tools](https://www.mongodb.com/try/download/database-tools)
- A `config` file as detailed above.

## How to run
To see all the available options, run the script in terminal with the `mongobackup help` argument to see options.

**Basic usage:**
- After setting up your `config` file, you can just run `mongobackup create` to have the tool create a DB dump in $USER/MONGODB_DUMP.
