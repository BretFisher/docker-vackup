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
usage() {
    echo
    echo "========================================="
    echo "[ 1 ] - BACKUP VOLUMES"
    echo "[ 2 ] - LIST ALL VOLUMES BACKUP"
    echo "[ 3 ] - RESTORE VOLUMES BACKUP"
    echo "[ 4 ] - VOLUME LIST FILE"
    echo "[ 5 ] - DELETE THE CONTENTS OF THE VOLUMES BEFORE RESTORING "
    echo "[ h ] - HELP OUTPUT"
    echo "[ e ] - exit"
    echo "========================================="
    echo
    read -n 1 -t 60 -p 'Enter value: ' value;
    echo
}
function BAD() {
    echo
    echo "========================================="
    echo "=========== Unknown parameter ==========="
    echo "========================================="
    echo
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
function BACKUP_VOLUMES() {
    if [ -s $VOLUMES ]; then
        echo > /dev/null
    else
        echo 
        echo "VOLUMES File is empty "
        sleep 2
        return 1
    fi
    countdown 5
    DATE=$(date +%Y-%m-%d--%H-%M-%S)
    cd $DIR
    volume_log_file="$DIR/volume_log_file.log"
    echo -n "" > $volume_log_file
    mkdir -p $DIR/backup-${DATE} && cd "$_"
    echo
#    CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
#    for CONTAINER in $CONTAINERS
#    do
#        echo "========================================="
#        echo "docker stop ${CONTAINER}"
#        docker stop ${CONTAINER}
#        echo "========================================="
#    done
    for VOLUME in $(cat $VOLUMES)
    do
        CONTAINER=$(docker ps -a --format "{{.Names}}" --filter volume=$VOLUME)
        if [ -n "$CONTAINER" ]; then
            for CONTAINER_NAME in $CONTAINER
            do
            container_status=$(docker inspect --format "{{.State.Status}}" "$CONTAINER_NAME")
            # Check if the container is running
            if [ "$container_status" == "running" ]; then
                echo "Container $CONTAINER_NAME is running"
                echo "DOCKER       STOP ==> $CONTAINER_NAME <=="
                echo "DOCKER       STOP ==> $CONTAINER_NAME <==" >> $volume_log_file
                echo "DOCKER       STOP ==> $CONTAINER_NAME <==" >> $BACKUP_FILE_LOG
                docker stop $CONTAINER_NAME
            else
                echo "Container $CONTAINER_NAME is not running"
                echo "DOCKER IS  STOPED ==> $CONTAINER_NAME <=="
                echo "DOCKER IS  STOPED ==> $CONTAINER_NAME <==" >> $volume_log_file
                echo "DOCKER IS  STOPED ==> $CONTAINER_NAME <==" >> $BACKUP_FILE_LOG
            fi
            done
        fi
    done
    for VOLUME in $(cat $VOLUMES)
    do
        DOCKER_VOLUME=$(docker volume ls  --format '{{.Name}}' | grep ${VOLUME}$)
        if [[ "$VOLUME" = "$DOCKER_VOLUME" ]]; then
            echo "========================================="
            echo "Run backup for Docker volume $VOLUME"
            echo "BACKED UP The VOLUME     ==> $VOLUME <== in the LIST" >> $volume_log_file
            echo "BACKED UP The VOLUME     ==> $VOLUME <== in the LIST" >> $BACKUP_FILE_LOG
            $VACKUP export $VOLUME $VOLUME.tgz
            if tar -tzf "$VOLUME.tgz" &> /dev/null; then
                echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== WAS CREATED SUCCESSFULLY" >> $volume_log_file
                echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== WAS CREATED SUCCESSFULLY" >> $BACKUP_FILE_LOG
            else
                echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== HAS ERRORS" >> $volume_log_file
                echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== HAS ERRORS" >> $BACKUP_FILE_LOG
                echo "THE TAR-GZ FILE          ==> $VOLUME.tgz <== HAS ERRORS" >> $BACKUP_FILE_LOG_ERROR
            fi
            echo "========================================="
        else
            echo "NOT BACKED UP the VOLUME ==> $VOLUME <== in the LIST" >> $volume_log_file
            echo "NOT BACKED UP the VOLUME ==> $VOLUME <== in the LIST" >> $BACKUP_FILE_LOG
            echo "==================================================================================" >> $volume_log_file
            echo "==================================================================================" >> $BACKUP_FILE_LOG
        fi
        echo "==================================================================================" >> $volume_log_file
        echo "==================================================================================" >> $BACKUP_FILE_LOG
    done
    for VOLUME in $(cat $VOLUMES)
    do
        CONTAINER=$(docker ps -a --format "{{.Names}}" --filter volume=$VOLUME)
        if [ -n "$CONTAINER" ]; then
            for CONTAINER_NAME in $CONTAINER
            do
            container_status=$(docker inspect --format "{{.State.Status}}" "$CONTAINER_NAME")
            # Check if the container is running
            if [ "$container_status" == "running" ]; then
                echo "Container $CONTAINER_NAME is running"
                echo "DOCKER IS STARTED ==> $CONTAINER_NAME <=="
                echo "DOCKER IS STARTED ==> $CONTAINER_NAME <==" >> $volume_log_file
                echo "DOCKER IS STARTED ==> $CONTAINER_NAME <==" >> $BACKUP_FILE_LOG
            else
                echo "Container $CONTAINER_NAME is not running"
                echo "DOCKER       START ==> $CONTAINER_NAME <=="
                echo "DOCKER       START ==> $CONTAINER_NAME <==" >> $volume_log_file
                echo "DOCKER       START ==> $CONTAINER_NAME <==" >> $BACKUP_FILE_LOG
                docker start $CONTAINER_NAME
            fi
            done
        fi
    done
#    for CONTAINER in $CONTAINERS
#    do
#       echo "========================================="
#       echo "docker start ${CONTAINER}"
#       docker start ${CONTAINER}
#       echo "========================================="
#    done
    echo
    cat $volume_log_file
    echo
    [ ! -f "$volume_log_file" ] && echo > /dev/null || rm -fv $volume_log_file
    echo
    find ${DIR}/backup-* -mtime +${ROTATE_DAYS} -exec rm -rvf {} +
    echo
    cd $BDIR
    LIST_BACKUP
}
function VOLUME_LIST() {
    echo
    if [ -s $VOLUMES ]; then
        echo "========================================="
        echo "=============== VOLUME LIST ============="
        echo "========================================="
        echo "`cat ${VOLUMES}`"
        echo "========================================="
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
    echo "========================================="
    echo "=========== ALL BACKUPS FOLDER =========="
    echo "========================================="
    for folder in $(ls -d backup-*); do
        echo "[ ${i} ] - ${folder}"
        FOLDER_SELECTION[${i}]="${folder}"
        ((i++))
    done
    echo "========================================="
    cd $BDIR
    echo
    sleep 1
}
function RESTORE_BACKUP() {
    countdown 5
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
    echo "========================================="
    echo "=========== ALL BACKUPS FOLDER =========="
    echo "========================================="
    for folder in $(ls -d backup-*); do
        echo "[ ${i} ] - ${folder}"
        FOLDER_SELECTION[${i}]="${folder}"
        ((i++))
    done
    echo "========================================="
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
    countdown 5
    echo
    echo "Do you want ALL DOCKER Volume delete befor RESTORE"
    echo
    echo "========================================="
    echo " [ y ] - YES"
    echo " [ n ] - NO"
    echo "========================================="
    echo
    read -n 1 -p 'Enter your answer value: ' value_restore;
    echo
    if [[ "$value_restore" =~ (y|Y) ]]; then
        DELETE_BEFOR_RESTORE
    else
        echo > /dev/null
    fi
    volume_restor_log_file="$DIR/volume_restore_log_file.log"
    echo -n "" > $volume_restor_log_file
#    for VOLUME in $(cat $VOLUMES)
#    do
#        echo "========================================="
#        echo " Run restore for Docker volume $VOLUME"
#        $VACKUP import $VOLUME.tgz $VOLUME
#        echo " RESTORE The VOLUME ==> $VOLUME <== in the LIST " >> $volume_restor_log_file
#        echo "========================================="
#    done
    for VOLUME in $(cat $VOLUMES)
    do
        CONTAINER=$(docker ps -a --format "{{.Names}}" --filter volume=$VOLUME)
        if [ -n "$CONTAINER" ]; then
            for CONTAINER_NAME in $CONTAINER
            do
            container_status=$(docker inspect --format "{{.State.Status}}" "$CONTAINER_NAME")
            # Check if the container is running
            if [ "$container_status" == "running" ]; then
                echo "Container $CONTAINER_NAME is running"
                echo "DOCKER       STOP ==> $CONTAINER_NAME <=="
                echo "DOCKER       STOP ==> $CONTAINER_NAME <==" >> $volume_restor_log_file
                docker stop $CONTAINER_NAME
            else
                echo "Container $CONTAINER_NAME is not running"
                echo "DOCKER IS  STOPED ==> $CONTAINER_NAME <=="
                echo "DOCKER IS  STOPED ==> $CONTAINER_NAME <==" >> $volume_restor_log_file
            fi
            done
        fi
    done
    for VOLUME in $(cat $VOLUMES)
    do  
        VOLUMES_TGZ=$(find * -name "${VOLUME}.tgz" 2>/dev/null)
        if [[ ${VOLUME}.tgz = $VOLUMES_TGZ ]]; then
            echo "========================================="
            echo "Run restore for Docker volume $VOLUME"
            $VACKUP import $VOLUME.tgz $VOLUME
            echo "RESTORE The VOLUME ==> $VOLUME <== in the LIST " >> $volume_restor_log_file
            echo "========================================="
        else
            echo "========================================="
            echo "NOT FIND TGZ IN THE FOLDER FROM $VOLUME "
            echo "NOT FIND TGZ IN THE FOLDER FROM VOLUME ==> $VOLUME <== " >> $volume_restor_log_file
            echo "NOT RESTORE THE VOLUME ==================> $VOLUME <== in the LIST " >> $volume_restor_log_file
            echo "========================================="
        fi
    done
    echo
#    for CONTAINER in $CONTAINERS
#    do
#        echo "========================================="
#        echo " docker start ${CONTAINER}"
#        docker start ${CONTAINER}
#        echo "========================================="
#    done
    for VOLUME in $(cat $VOLUMES)
    do
        CONTAINER=$(docker ps -a --format "{{.Names}}" --filter volume=$VOLUME)
        if [ -n "$CONTAINER" ]; then
            for CONTAINER_NAME in $CONTAINER
            do
            container_status=$(docker inspect --format "{{.State.Status}}" "$CONTAINER_NAME")
            # Check if the container is running
            if [ "$container_status" == "running" ]; then
                echo "Container $CONTAINER_NAME is running"
                echo "DOCKER IS STARTED ==> $CONTAINER_NAME <=="
                echo "DOCKER IS STARTED ==> $CONTAINER_NAME <==" >> $volume_restor_log_file
            else
                echo "Container $CONTAINER_NAME is not running"
                echo "DOCKER      START ==> $CONTAINER_NAME <=="
                echo "DOCKER      START ==> $CONTAINER_NAME <==" >> $volume_restor_log_file
                docker start $CONTAINER_NAME
            fi
            done
        fi
    done
    cat $volume_restor_log_file
    echo
    [ ! -f "$volume_restor_log_file" ] && echo > /dev/null || rm -fv $volume_restor_log_file
    cd $BDIR
}
function DELETE_BEFOR_RESTORE() {
    CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
    # VOLUME_LIST
    sleep 1
    # if ! $1 ;
    # then
        # return 1
    # fi
    echo " VOLUMES BEFORE RESTORE DELETE"
    countdown 5
    volume_delete_log_file="$DIR/volume_delete_log_file.log"
    echo -n "" > $volume_delete_log_file
    for VOLUME in $(cat $VOLUMES)
    do
        CONTAINER=$(docker ps -a --format "{{.Names}}" --filter volume=$VOLUME)
        if [ -n "$CONTAINER" ]; then
            for CONTAINER_NAME in $CONTAINER
            do
            container_status=$(docker inspect --format "{{.State.Status}}" "$CONTAINER_NAME")
            # Check if the container is running
            if [ "$container_status" == "running" ]; then
                echo "Container $CONTAINER_NAME is running"
                echo "DOCKER       STOP ==> $CONTAINER_NAME <=="
                echo "DOCKER       STOP ==> $CONTAINER_NAME <==" >> $volume_delete_log_file
                docker stop $CONTAINER_NAME
            else
                echo "DOCKER IS  STOPED ==> $CONTAINER_NAME <=="
                echo "DOCKER IS  STOPED ==> $CONTAINER_NAME <==" >> $volume_delete_log_file
                echo "Container $CONTAINER_NAME is not running"
            fi
            done
        fi
    done
#    for CONTAINER in $CONTAINERS; do echo -e "\\ndocker stop ${CONTAINER}"; done
#    for CONTAINER in $CONTAINERS
#    do
#        echo "========================================="
#        echo " docker stop ${CONTAINER}"
#        docker stop ${CONTAINER}
#        echo "========================================="
#    done
    for VOLUME in $(cat $VOLUMES)
    do
        if ! docker volume inspect --format '{{.Name}}' "$VOLUME"; then
            echo "Error: Volume $VOLUME does not exist"
            echo "Docker create Volume $VOLUME "
            echo "Error: Volume $VOLUME does not exist" >> $volume_delete_log_file
            echo "Docker create Volume $VOLUME " >> $volume_delete_log_file
            docker volume create "$VOLUME"
        fi
        if ! docker run --rm -v "$VOLUME":/vackup-volume busybox sh -c 'rm -Rfv /vackup-volume/*'; then
            echo "Error: Failed to start busybox container"
            echo "Error: Failed to start busybox container" $volume_delete_log_file
        else
            echo "Successfully delete $VOLUME"
            echo "Successfully delete $VOLUME" $volume_delete_log_file
        fi
    done
    echo
    cat $volume_delete_log_file
    echo
    sleep 5
    [ ! -f "$volume_delete_log_file" ] && echo > /dev/null || rm -fv $volume_delete_log_file
    echo
}
while [ true ];
do
    usage;
    case "$value" in
        1)
            BACKUP_VOLUMES
            ;;
        2)
            LIST_BACKUP
            ;;
        3)
            RESTORE_BACKUP
            ;;
        4)
            VOLUME_LIST
            ;;
        5)
            DELETE_BEFOR_RESTORE
            ;;
        h)
            usage
            ;;
        e)
            exit 1
            ;;
        *)
            BAD
            break
            ;;
    esac
done
