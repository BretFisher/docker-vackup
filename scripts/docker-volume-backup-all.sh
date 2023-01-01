#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/scripts/docker-volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
BDIR="$PWD"
DIR="/opt/backup-volume"
SCRIPT_DIR="/opt/scripts"
VOLUMES="$SCRIPT_DIR/docker-volume-list.txt"
VACKUP="/usr/local/bin/vackup"
DATE=$(date +%Y-%m-%d--%H-%M-%S)
ROTATE_DAYS="30"
BACKUP_FILE_LOG="backup-file.log"
BACKUP_FILE_LOG_ERROR="backup-error.log"

if [ -f "$VACKUP" ]; then
    echo > /dev/null
else
    echo
    echo "vackup not installed"
    echo "curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/vackup > $VACKUP && chmod +x $VACKUP"
    exit 1
fi
if [ -f "$VOLUMES" ]; then
    if [ -s $VOLUMES ]; then
        echo > /dev/null
    else
        echo
        echo "BACKUP VOLUMES File is empty "
        echo "Create a File of your DOCKER VOLUMES"
        echo "==> docker volume ls --format '{{.Name}}' > $VOLUMES <== "
        echo
        exit 1
    fi
else
    echo
    echo "VOLUMES File does not exist . "
    echo "Create a File of your DOCKER VOLUMES "
    echo "==> docker volume ls --format '{{.Name}}' > $VOLUMES <== "
    echo "OR Change the Variable VOLUMES= "
    echo
    exit 1
fi
if [ -d "$DIR" ]; then
    echo > /dev/null
else
    echo
    echo "BACKUP Directory does not exist."
    echo "Create a BACKUP Directory or change the variable DIR= "
    echo "==> mkdir -p $DIR <== "
    echo "OR Change the Variable DIR= "
    echo
    exit 1
fi

cd $DIR
volume_log_file="$DIR/volume_log_file.log"
echo -n "" > $volume_log_file
mkdir -p $DIR/backup-${DATE} && cd "$_"

for VOLUME in $(cat $VOLUMES)
do
    DOCKER_VOLUME=$(docker volume ls  --format '{{.Name}}' | grep ${VOLUME}$)
    if [[ "$VOLUME" = "$DOCKER_VOLUME" ]]; then
        echo "========================================="
        echo "Run backup for Docker volume $VOLUME"
        echo "BACKED UP The VOLUME     ==> $VOLUME <== in the LIST"
        echo "BACKED UP The VOLUME     ==> $VOLUME <== in the LIST" >> $volume_log_file
        echo "BACKED UP The VOLUME     ==> $VOLUME <== in the LIST" >> $BACKUP_FILE_LOG
        $VACKUP export $VOLUME $VOLUME.tgz
        if tar -tzf "$VOLUME.tgz" &> /dev/null; then
            echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== WAS CREATED SUCCESSFULLY"
            echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== WAS CREATED SUCCESSFULLY" >> $volume_log_file
            echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== WAS CREATED SUCCESSFULLY" >> $BACKUP_FILE_LOG
        else
            echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== HAS ERRORS"
            echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== HAS ERRORS" >> $volume_log_file
            echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== HAS ERRORS" >> $BACKUP_FILE_LOG
            echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== HAS ERRORS" >> $BACKUP_FILE_LOG_ERROR
        fi
        echo "========================================="
    else
        echo "NOT BACKED UP the VOLUME ==> $VOLUME <== in the LIST"
        echo "NOT BACKED UP the VOLUME ==> $VOLUME <== in the LIST" >> $volume_log_file
        echo "NOT BACKED UP the VOLUME ==> $VOLUME <== in the LIST" >> $BACKUP_FILE_LOG
        echo "==================================================================================" >> $volume_log_file
        echo "==================================================================================" >> $BACKUP_FILE_LOG
    fi
    echo "==================================================================================" >> $volume_log_file
    echo "==================================================================================" >> $BACKUP_FILE_LOG
done

echo
cat $volume_log_file
echo
[ ! -f "$volume_log_file" ] && echo > /dev/null || rm -fv $volume_log_file
echo
find ${DIR}/backup-* -mtime +${ROTATE_DAYS} -exec rm -rvf {} +
echo
cd $BDIR
