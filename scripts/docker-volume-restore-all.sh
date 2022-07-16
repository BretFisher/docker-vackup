#!/bin/bash
# VOLUMES=$(docker volume ls  --format '{{.Name}}' > /opt/scripts/docker-volume-list.txt)
# VOLUMES=$(docker volume ls  --format '{{.Name}}')
VOLUMES=$(cat /opt/scripts/docker-volume-list.txt)
BDIR="$PWD"
DIR="/opt/backup-volume"
usage() {
    echo
    echo "======================================"
    echo "[ 1 ] - LIST ALL BACKUP"
    echo "[ 2 ] - RESTORE BACKUP"
    echo "[ h ] - HELP OUTPUT"
    echo "[ e ] - exit"
    echo "======================================"
    echo
    read -p 'Enter value: ' value;
}
function countdown() {
  secs=$1
  shift
  msg=$@
  while [ $secs -gt 0 ]
  do
    printf "\r\033[KWaiting %.d seconds $msg" $((secs--))
    sleep 1
  done
  echo
}
function BAD() {
    echo
    echo "======================================"
    echo "Unknown parameter"
}
function LIST_BACKUP() {
    cd $DIR
    i=1
    declare -A FOLDER_SELECTION
    if [[ $(find ${DIR}/backup-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
        echo
        echo "Location has no backups"
        exit 1
    fi
    echo
    echo "======================================"
    echo "======== ALL BACKUPS FOLDER==========="
    echo "======================================"
    for folder in $(ls -d backup-*); do
        echo "[ ${i} ] - ${folder}"
        FOLDER_SELECTION[${i}]="${folder}"
        ((i++))
    done
    echo "======================================"
    cd $BDIR
    echo
}
function RESTORE_BACKUP() {
    cd $DIR
    i=1
    declare -A FOLDER_SELECTION
    if [[ $(find ${DIR}/backup-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
        echo
        echo "Location has no backups"
        usage;
    fi
    echo
    echo "======================================"
    echo "======== ALL BACKUPS FOLDER==========="
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
    countdown 10
    for VOLUME in $VOLUMES
    do
        echo "========================================="
        echo "Run restore for Docker volume $VOLUME"
        /usr/local/bin/vackup import $VOLUME.tgz $VOLUME
        echo "========================================="
    done
    cd $BDIR
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
            break
            ;;
        h)
            usage
            ;;
        e)
            exit 1
            ;;
        *)
            BAD
            ;;
    esac
done
