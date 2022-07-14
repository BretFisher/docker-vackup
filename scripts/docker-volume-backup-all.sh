#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/backup-volume/volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES=$(cat /opt/backup-volume/volume-list.txt)
BDIR="$PWD"
DIR="/opt/backup-volume"
DATE=$(date +%Y-%m-%d--%H-%M)
ROTATE_DAYS=30
cd $DIR
# mkdir -p ./backup-${DATE} && cd $_
mkdir -p $DIR/backup-${DATE} && cd "$_"
for VOLUME in $VOLUMES
do
  echo "========================================="
  echo "Run backup for Docker volume $VOLUME "
  /usr/local/bin/vackup export $VOLUME $VOLUME.tgz
  echo "========================================="
done
find $DIR/backup-* -mtime +$ROTATE_DAYS -exec rm -rvf {} \;
cd $BDIR
