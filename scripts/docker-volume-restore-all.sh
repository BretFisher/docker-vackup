#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/backup-volume/volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES=$(cat /opt/backup-volume/volume-list.txt)
DIR=/opt/backup-volume
cd $DIR

for VOLUME in $VOLUMES
do
  echo "Run restore for Docker volume $VOLUME"
  /usr/local/bin/vackup import $VOLUME.tgz $VOLUME 
done
