#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/scripts/docker-volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES=$(cat /opt/scripts/docker-volume-list.txt)
CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
BDIR="$PWD"
DIR="/opt/backup-volume"
DATE=$(date +%Y-%m-%d--%H-%M)
ROTATE_DAYS=30
cd $DIR
for CONTAINER in $CONTAINERS
do
  echo "========================================="
  echo "docker stop $CONTAINER"
  docker stop $CONTAINER
  echo "========================================="
done
mkdir -p $DIR/backup-${DATE} && cd "$_"
for VOLUME in $VOLUMES
do
  echo "========================================="
  echo "Run backup for Docker volume $VOLUME "
  /usr/local/bin/vackup export $VOLUME $VOLUME.tgz
  echo "========================================="
done
for CONTAINER in $CONTAINERS
do
  echo "========================================="
  echo "docker start $CONTAINER"
  docker start $CONTAINER
  echo "========================================="
done
find $DIR/backup-* -mtime +$ROTATE_DAYS -exec rm -rvf {} \;
cd $BDIR
