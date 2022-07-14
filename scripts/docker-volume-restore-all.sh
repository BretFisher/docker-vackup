#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/backup-volume/volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES=$(cat /opt/backup-volume/volume-list.txt)
BDIR="$PWD"
DIR="/opt/backup-volume"
usage() {
    echo "======================================"
    echo " 1 = LIST ALL BACKUP"
    echo " 2 = RESTORE BACKUP"
    echo " h = HELP OUTPUT"
    echo " e = exit"
    read -p 'Enter value: ' value;
}
function BAD() {
    echo "======================================"
    read -p 'Enter value: ' value;
}
function LIST_BACKUP() {
    cd $DIR
    echo "======================================"
    echo "======== ALL BACKUPS FOLDER==========="
    echo "======================================"
    ls | grep "backup-*"
    echo "======================================"
    cd $BDIR
}
function RESTORE_BACKUP() {
    cd $DIR
    echo "======================================"
    echo "======== ALL BACKUPS FOLDER==========="
    echo "======================================"
    ls | grep "backup-*"
    echo "======================================"
    read -p 'Enter the Name of the Folder: ' BACKUP_VOLUME;
    if [ "`ls | grep $BACKUP_VOLUME`" ]; then
        cd $BACKUP_VOLUME
        for VOLUME in $VOLUMES
        do
            echo "========================================="
            echo "Run restore for Docker volume $VOLUME"
            /usr/local/bin/vackup import $VOLUME.tgz $VOLUME
            echo "========================================="
        done
        cd $BDIR
    else
        echo "Error the Name is incorrect"
        usage;
    fi
}


while [ true ];
do
	usage;
    case "$value" in
        1)
            LIST_BACKUP
            ;;
        2)
            RESTORE_BACKUP
            # break
            ;;
        h)
            usage
            ;;
        e)
            exit 1
            ;;
        *)
            echo "Unknown parameter"
            BAD
            ;;
    esac
done
