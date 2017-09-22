#!/bin/bash
# Possible timestamps: s, m, h, D, W, M, or Y

## This script helps restoring and backing up data using Duplicity
## Target Machine is available via SSH, no password is used to login, only a Key

# Backup with Key only
#
export PASSPHRASE=


# SSH Location
#
TARGET_MACHINE="scp://name@machine:port"
TARGET_FOLDER="/relative/path"
SSH_LOGIN="name@machine"
SSH_PORT="Port"
RESTORE_PATH="/local/restore/folder"
KEYPATH=".ssh/private_key"


# Is SSH server available?
#
function ssh_server_test {

ssh -p ${SSH_PORT} -q ${SSH_LOGIN} exit
ssh_is_up=$(echo $?)

if [ ${ssh_is_up} = 0 ]; then
	echo -e "Backup machine is available. That is good..."
	sleep 1
	ask_user
else
	echo -e "Backup machine is not available. \nPlease take care to get your backup machine online or adapt this script.\nQuitting."
	exit
fi
}

function ask_user {
	echo -e "If you want to backup files, press [1]."
    echo -e "If you want to recovr files, press [2]." 
    read -p "> " decision
        case ${decision} in
            1)
                #start_duplicity_backup
                echo "Start Backup"
                start_duplicity_backup
                ;;
            2)
                echo "Start Restore"
		start_duplicity_restore
                ;;
            3)
                echo "Quitting, goodbye!"
                exit 0
                ;;
            *)
                echo "Please chose between [1] or [2] or press [3] for quitting the program."
                ask_user
                ;;
        esac
}


# Start Restore-Prozess. 
# Show Content of Backup, let User chose by number
#
function start_duplicity_restore {
    echo -e "Would you like to take a look at the date and type of backups? [1]"
    echo -e "Would you like to see the available files in your backup? [2]"
    echo -e "Would you like to restore a file or folder? [3]"
    echo -e "Would you like to restore the full backup? [4]"
    read -p "> " decision
        case ${decision} in
            1)
                echo "Getting data, this can take a little time..."
                get_backup_infos
                ;;
            2)
                echo "Get data..."
                list_files_in_backup
                ;;
            3)
                echo "Chose a folder or file to restore."
                restore_folder_file
                ;;
            4)
                echo "Starting a full restore..."
                restore_full
                ;;
	q | Q)
		echo "Quitting."
		exit 0
		;;
            *)
                echo "Please chose one of the numbers or [Q] for quit."
                start_duplicity_restore
                ;;
        esac
}


# Get infos from backup 
# Show number and dates from backup
#
function get_backup_infos {
    duplicity --no-encryption \
    collection-status \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    ${TARGET_MACHINE}${TARGET_FOLDER} | grep "Full\|Incremental"
    start_duplicity_restore
    }

# Get list of files in backup
# list is saved in archive.data
#
function list_files_in_backup {
    duplicity --no-encryption \
    list-current-files \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    ${TARGET_MACHINE}${TARGET_FOLDER} > archive.data
    }


    
# Start Backup if SSH is available
# Take care of tabs in duplicity command
# 
function start_duplicity_backup {

# Backup files and folders
nice -n 10 duplicity --no-encryption \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    --full-if-older-than 12M \
    --include /home/user/.ssh \
    --include /home/user/.gnupg \
    --include /home/user/Dokumente \
    --include /home/user/.thunderbird \
    --include /home/user/Software \
    --include /home/user/Videos \
    --include /home/user/Bilder \
    --exclude /home/user \
    /home/user \
    ${TARGET_MACHINE}${TARGET_FOLDER}
}

ssh_server_test
