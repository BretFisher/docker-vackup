#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/scripts/docker-volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES="/opt/scripts/docker-volume-list.txt"
BDIR="$PWD"
DIR="/opt/backup-volume"
DATE=$(date +%Y-%m-%d--%H-%M)
ROTATE_DAYS=30
if [ -f "$VOLUMES" ]; then
    echo 
else
    echo
    echo " VOLUMES File does not exist . "
    echo " Create a File of your DOCKER VOLUMES "
    echo " ==> docker volume ls  --format '{{.Name}}' > $VOLUMES <== "
    echo " OR Change the variable VOLUMES= "
    echo
    exit 1	
fi
if [ -d "$DIR" ]; then
    echo 
else
    echo 
    echo " BACKUP Directory does not exist."
    echo " Create a BACKUP Directory or change the variable DIR= "
    echo " ==> mkdir -p $DIR <== "
    echo " Or Change the variable DIR= " 
    echo
    exit 1
fi
cd $DIR
mkdir -p $DIR/backup-${DATE} && cd "$_"
for VOLUME in $(cat $VOLUMES)
do
    echo "========================================="
    echo "Run backup for Docker volume $VOLUME "
    /usr/local/bin/vackup export $VOLUME $VOLUME.tgz
    echo "========================================="
done
find $DIR/backup-* -mtime +$ROTATE_DAYS -exec rm -rvf {} \;
cd $BDIR