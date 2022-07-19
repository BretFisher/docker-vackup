#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/scripts/docker-volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES="/opt/scripts/docker-volume-list.txt"
BDIR="$PWD"
DIR="/opt/backup-volume"
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
usage() {
    echo
    echo "======================================"
    echo "[ 1 ] - LIST ALL BACKUP"
    echo "[ 2 ] - RESTORE BACKUP"
    # echo "[ 3 ] - DELETE THE CONTENTS OF THE VOLUMES BEFORE RESTORING "
    echo "[ l ] - VOLUME LIST FILE"	
    echo "[ h ] - HELP OUTPUT"
    echo "[ e ] - exit"
    echo "======================================"
    echo
    read -p 'Enter value: ' value;
}
function BAD() {
    echo
    echo "======================================"
    echo "Unknown parameter"
    sleep 2
    return 1	
}
function countdown() {
  secs=$1
  shift
  msg=$@
  while [ $secs -gt 0 ]
  do
    printf "\r\033[KWaiting %.d seconds or Cancel ctrl+c $msg" $((secs--))
    sleep 1
  done
  echo
}
function VOLUME_LIST() {
    if [ -s $VOLUMES ]; then
        echo "========================================="
        echo "============ VOLUME LIST ================"
        cat $VOLUMES
        echo -e "\\n========================================="
        sleep 2
        return 0
    else
        echo 
        echo " VOLUMES File is empty "
        sleep 2
        return 1
    fi
}
function LIST_BACKUP() {
    cd $DIR
    i=1
    declare -A FOLDER_SELECTION
    if [[ $(find ${DIR}/backup-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
        echo
        echo "Location has no backups"
        sleep 1
        return 1
    fi
    echo
    echo "======================================"
    echo "======== ALL BACKUPS FOLDER =========="
    echo "======================================"
    for folder in $(ls -d backup-*); do
        echo "[ ${i} ] - ${folder}"
        FOLDER_SELECTION[${i}]="${folder}"
        ((i++))
    done
    echo "======================================"
    cd $BDIR
    echo
    sleep 1
}
function RESTORE_BACKUP() {
    cd $DIR
    CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)    
    i=1
    declare -A FOLDER_SELECTION
    if [[ $(find ${DIR}/backup-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
        echo
        echo "Location has no backups"
        sleep 1
        return 1
    fi
    echo
    echo "======================================"
    echo "======== ALL BACKUPS FOLDER =========="
    echo "======================================"
    for folder in $(ls -d backup-*); do
        echo "[ ${i} ] - ${folder}"
        FOLDER_SELECTION[${i}]="${folder}"
        ((i++))
    done
    echo "======================================"
    echo
    input_sel=0
    while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
        read -p "Select a restore point: " input_sel
    done
    echo
    RESTORE_POINT="${DIR}/${FOLDER_SELECTION[${input_sel}]}/"
    cd $RESTORE_POINT
    if [ "$(find * -name "*.tgz" 2>/dev/null)" ]; then
        echo > /dev/null
    else
        echo "Not .tgz found"
        return 1
    fi
    countdown 10
    DELETE_BEFOR_RESTORE
    volume_restor_log_file="$DIR/volume_restore_log_file.log"
    echo "" > $volume_restor_log_file
    for VOLUME in $(cat $VOLUMES)
    do
        echo "========================================="
        echo " Run restore for Docker volume $VOLUME"
        /usr/local/bin/vackup import $VOLUME.tgz $VOLUME
        echo " RESTORE The VOLUME ==> $VOLUME <== in the LIST " >> $volume_restor_log_file
        echo "========================================="
    done
    echo
    for CONTAINER in $CONTAINERS
    do
        echo "========================================="
        echo " docker start $CONTAINER"
        docker start $CONTAINER
        echo "========================================="
    done
    cat $volume_restor_log_file
    echo
    
    [ ! -f "$volume_restor_log_file" ] && echo > /dev/null || rm -fv $volume_restor_log_file
    cd $BDIR
    exit 1
}
function DELETE_BEFOR_RESTORE() {
    CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
    # VOLUME_LIST	
    sleep 1
    if ! $1 ; 
    then
        return 1
    fi
    countdown 10
    for CONTAINER in $CONTAINERS; do echo -e "\\ndocker stop $CONTAINER"; done
    for CONTAINER in $CONTAINERS
    do
        echo "========================================="
        echo "docker stop $CONTAINER"
        docker stop $CONTAINER
        echo "========================================="
    done
    for VOLUME in $(cat $VOLUMES)
    do
        if ! docker volume inspect --format '{{.Name}}' "$VOLUME"; then
            echo " Error: Volume $VOLUME does not exist"
            echo " Docker create Volume $VOLUME "
            docker volume create "$VOLUME"
        fi
        if ! docker run --rm -v "$VOLUME":/vackup-volume  busybox rm -Rfv /vackup-volume/*; then
            echo " Error: Failed to start busybox container"
        else
            echo "Successfully deleite $VOLUME"
        fi
    done
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
            ;;
        # 3)
            # DELETE_BEFOR_RESTORE
            # ;;
        h)
            usage
            ;;
        l)
            VOLUME_LIST
            ;;
        e)
            exit 1
            ;;
        *)
            BAD
            ;;
    esac
done
