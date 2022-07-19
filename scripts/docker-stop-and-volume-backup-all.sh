#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/scripts/docker-volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES="/opt/scripts/docker-volume-list.txt"
CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
BDIR="$PWD"
DIR="/opt/backup-volume"
DATE=$(date +%Y-%m-%d--%H-%M)
ROTATE_DAYS=30
if [ -f "/usr/local/bin/vackup" ]; then
    echo > /dev/null
else
    echo
    echo " vackup not installed"
    echo " curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/vackup > /usr/local/bin/vackup && chmod +x /usr/local/bin/vackup"
    exit 1
fi 
if [ -f "$VOLUMES" ]; then
    if [ -s $VOLUMES ]; then
        echo > /dev/null
    else
        echo 
        echo " BACKUP VOLUMES File is empty "
        echo " Create a File of your DOCKER VOLUMES"
        echo " ==> docker volume ls --format '{{.Name}}' > $VOLUMES <== "
        echo
        exit 1
    fi  
else
    echo 
    echo " VOLUMES File does not exist . "
    echo " Create a File of your DOCKER VOLUMES "
    echo " ==> docker volume ls --format '{{.Name}}' > $VOLUMES <== "
    echo " OR Change the Variable VOLUMES= "
    echo
    exit 1
fi

if [ -d "$DIR" ]; then
    echo > /dev/null
else
    echo 
    echo " BACKUP Directory does not exist."
    echo " Create a BACKUP Directory or change the variable DIR= "
    echo " ==> mkdir -p $DIR <== "
    echo " OR Change the Variable DIR= " 
    echo
    exit 1
fi
for CONTAINER in $CONTAINERS
do
    echo "========================================="
    echo "docker stop $CONTAINER"
    docker stop $CONTAINER
    echo "========================================="
done
cd $DIR
volume_log_file="$DIR/volume_log_file.log"
echo "" > $volume_log_file
mkdir -p $DIR/backup-${DATE} && cd "$_"
for VOLUME in $(cat $VOLUMES)
do
    DOCKER_VOLUME=$(docker volume ls  --format '{{.Name}}' | grep $VOLUME)
    if [[ "$VOLUME" = "$DOCKER_VOLUME" ]]; then
        echo "========================================="
        echo " Run backup for Docker volume $VOLUME "
        echo " BACKED UP The VOLUME     ==> $VOLUME <== in the LIST " >> $volume_log_file
        /usr/local/bin/vackup export $VOLUME $VOLUME.tgz
        echo "========================================="		
    else
        echo " NOT BACKED UP the VOLUME ==> $VOLUME <== in the LIST " >> $volume_log_file
    fi
done
for CONTAINER in $CONTAINERS
do
   echo "========================================="
   echo "docker start $CONTAINER"
   docker start $CONTAINER
   echo "========================================="
done
echo
cat $volume_log_file
echo
[ ! -f "$volume_log_file" ] && echo > /dev/null || rm -fv $volume_log_file
echo
find $DIR/backup-* -mtime +$ROTATE_DAYS -exec rm -rvf {} \;
echo
cd $BDIR

