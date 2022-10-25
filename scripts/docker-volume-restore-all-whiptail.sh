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
set -o errexit
set -o errtrace
set -o nounset
set -Eeo pipefail
if [ -f "/usr/bin/whiptail" ]; then
    echo > /dev/null
else
    echo
    echo " Whiptail not installed"
    echo " Install Whiptail"
    echo " ==> sudo apt update && sudo apt install whiptail <== "
    echo
    echo
    echo " DO you want to install Whiptail for Debian / Mint / Ubuntu"
    echo "========================================="
    echo "[ Y ] - INSTALL WHIPTAIL"
    echo "[ N ] - EXIT"
    echo "========================================="
    echo
    read -n 1 -t 60 -p 'Enter your answer value: ' value_whiptail;
    if [[ "$value_whiptail" =~ (y|Y) ]]; then
        sudo apt update && apt install whiptail -yq
    else
        echo
        exit 1
    fi
fi
if [ -f "/usr/bin/tree" ]; then
    echo > /dev/null
else
    echo
    echo " Tree not installed"
    echo " Install Tree"
    echo " ==> sudo apt update && sudo apt install tree <== "
    echo
    echo
    echo " DO you want to install Tree for Debian / Mint / Ubuntu"
    echo "========================================="
    echo "[ Y ] - INSTALL TREE"
    echo "[ N ] - EXIT"
    echo "========================================="
    echo
    read -n 1 -t 60 -p 'Enter your answer value: ' value_tree;
    echo
    if [[ "$value_tree" =~ (y|Y) ]]; then
        sudo apt update && apt install tree -yq
    else
        echo
        exit 1
    fi
fi 
if [ -f "$VACKUP" ]; then
    echo > /dev/null
else
    VBACKUP_NOT=$(
    echo "Vackup not installed"
    echo "curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/vackup > \ $VACKUP && chmod +x $VACKUP"
    echo
    echo "Do you want to Install"
    )
    if whiptail --title "VACKUP NOT INSTALL" --yesno "$VBACKUP_NOT" 20 100; then
        sudo curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/vackup > $VACKUP && chmod +x $VACKUP
        sleep 0.5
    else
        exit 1
    fi
fi 
if [ -d "$DIR" ]; then
    echo > /dev/null
else
    DIR_PATH=$(
    echo "BACKUP Directory is not exist."
    echo "Create a BACKUP Directory or change the variable DIR= "
    echo " ==> mkdir -p $DIR <== "
    echo "OR Change the Variable DIR= "
    echo
    echo "Do you want create Directory $DIR "
    )
    if whiptail --title "VACKUP NOT INSTALL" --yesno "$DIR_PATH" 20 100; then
        sleep 0.5
        mkdir -p $DIR
        sleep 0.5
    else
        exit 1
    fi
fi
if [ -f $VOLUMES ]; then
    echo > /dev/null
else
    BACKUP_VOLUMES_FILE=$(
    echo "BACKUP VOLUMES File is not exist."
    echo "Create a File of your DOCKER VOLUMES"
    echo " ==> docker volume ls --format '{{.Name}}' > $VOLUMES <== "
    echo
    echo "Do you want to create Directory $SCRIPT_DIR and the"
    echo "File $VOLUMES and save present volumes in  the FILE"
    )
    if whiptail --title "BACKUP VOLUMES File is EMTY" --yesno "$BACKUP_VOLUMES_FILE" 20 100; then
        sleep 1
        mkdir -p $SCRIPT_DIR && touch $VOLUMES
        docker volume ls --format '{{.Name}}' > $VOLUMES
        sleep 1
        VOLUME_LIST_FILE=$( 
        echo "=================================================================="
        echo "========================== VOLUME LIST ==========================="
        echo "=================================================================="
        echo "`cat ${VOLUMES}`"
        echo "=================================================================="
        )
        TERM=ansi whiptail --title "VOLUME LIST" --infobox "$VOLUME_LIST_FILE" 40 70
        # whiptail --title "VOLUME LIST" --scrolltext --msgbox "$VOLUME_LIST_FILE" 40 70
        sleep 4
        clear
    else
        exit 1
    fi
fi
function EXIT() {
EXIT=$(
echo "========================================="
echo "================= EXIT =================="
echo "========================================="
)
    # whiptail --msgbox "$EXIT" 11 45
    TERM=ansi whiptail --title "EXIT" --infobox "$EXIT" 11 45
    sleep 2
    clear
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
function countdown5() {
{
for ((i = 0 ; i <= 100 ; i+=5)); do
    sleep 0.2
    echo $i
done
} | whiptail --title "COUNTDOWN" --gauge "=============== COUNTDOWN ===============" 7 45 0
}
function BACKUP_VOLUMES() {
    if [ -s $VOLUMES ]; then
        echo > /dev/null
    else
        echo 
        # echo " VOLUMES File is empty "
        VOLUME_LIST_EMPTY=$(
        echo "========================================="
        echo "========= VOLUMES File is EMPTY ========="
        echo "========================================="
        )
        TERM=ansi whiptail --title " VOLUMES File is EMPTY" --infobox "VOLUME_LIST_EMPTY" 11 45
        sleep 5
        clear
        return 0
    fi
    # countdown5
    countdown 5
    DATE=$(date +%Y-%m-%d--%H-%M-%S)
    echo
    CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
    for CONTAINER in $CONTAINERS
    do
        echo "========================================="
        echo "docker stop ${CONTAINER}"
        docker stop ${CONTAINER}
        echo "========================================="
    done
    echo 
    cd $DIR
    volume_log_file="$DIR/volume_log_file.log"
    echo -n "" > $volume_log_file
    mkdir -p $DIR/backup-${DATE} && cd "$_"
    for VOLUME in $(cat $VOLUMES)
    do
        DOCKER_VOLUME=$(docker volume ls  --format '{{.Name}}' | grep ${VOLUME}$)
        if [[ "$VOLUME" = "$DOCKER_VOLUME" ]]; then
            echo "========================================="
            echo " Run backup for Docker volume $VOLUME "
            echo " BACKED UP The VOLUME     ==> $VOLUME <== in the LIST " >> $volume_log_file
            $VACKUP export $VOLUME $VOLUME.tgz
            echo "========================================="
        else
            echo " NOT BACKED UP the VOLUME ==> $VOLUME <== in the LIST " >> $volume_log_file
        fi
    done
    for CONTAINER in $CONTAINERS
    do
       echo "========================================="
       echo "docker start ${CONTAINER}"
       docker start ${CONTAINER}
       echo "========================================="
    done
    VOLUME_BACKUP_LOG=$(cat $volume_log_file)
    # TERM=ansi whiptail --title "BACKUP VOLUMES STATUS" --infobox "$VOLUME_BACKUP_LOG" 40 115
    whiptail --title "BACKUP VOLUMES STATUS" --scrolltext --msgbox "$VOLUME_BACKUP_LOG" 40 115
    echo
    [ ! -f "$volume_log_file" ] && echo > /dev/null || rm -fv $volume_log_file
    echo
    find ${DIR}/backup-* -mtime +${ROTATE_DAYS} -exec rm -rvf {} \;
    clear
    echo
    cd $BDIR
    LIST_BACKUP
}
function BACKUP_VOLUMES_MENU() {
    DOCKER_VOLUME_LS=$(docker volume ls  --format '{{.Name}}')
    if [[ -z $DOCKER_VOLUME_LS ]]; then
        # whiptail --title "NO DOCKER VOLUMES" --msgbox "NO DOCKER VOLUMES PRESENT" 8 29
        TERM=ansi whiptail --title "NO DOCKER VOLUMES" --infobox "NO DOCKER VOLUMES PRESENT" 8 29
        sleep 3
        clear
        return
    else
        echo > /dev/null
    fi
    # countdown5
    countdown 5
    DATE=$(date +%Y-%m-%d--%H-%M-%S)
    echo
    CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
    for CONTAINER in $CONTAINERS
    do
        echo "========================================="
        echo "docker stop ${CONTAINER}"
        docker stop ${CONTAINER}
        echo "========================================="
    done
    echo 
    cd $DIR
    i=1
    LIST_DOCKER_VOLUMES=$(
    for volume_ls in $DOCKER_VOLUME_LS; do
    echo "${i} ${volume_ls} OFF"
    ((i++))
    done
    )
    for volume_ls in $DOCKER_VOLUME_LS; do
        DOCKER_VOLUMES[${i}]="${volume_ls}"
        ((i++))
    done
    # echo "$LIST_DOCKER_VOLUMES"
    CHOICES=$(whiptail --separate-output --checklist "Choose options" 35 90 15 \
    `echo "$LIST_DOCKER_VOLUMES"` 3>&1 1>&2 2>&3)
    if [ -z "$CHOICES" ]; then
       clear
       return
    else
       echo "$CHOICES"
    fi
    sleep 2
    volume_log_file="$DIR/volume_log_file.log"
    echo -n "" > $volume_log_file
    mkdir -p $DIR/backup-${DATE} && cd "$_"
    for CHOICE_NUMBER in $CHOICES
    do
        VOLUME="${DOCKER_VOLUMES[${CHOICE_NUMBER}]}"
        DOCKER_VOLUME=$(docker volume ls  --format '{{.Name}}' | grep ${VOLUME}$)
        if [[ "$VOLUME" = "$DOCKER_VOLUME" ]]; then
            echo "========================================="
            echo " Run backup for Docker volume $VOLUME "
            echo "BACKED UP The VOLUME     ==> $VOLUME <== in the MENU " >> $volume_log_file
            $VACKUP export $VOLUME $VOLUME.tgz
            echo "========================================="
        else
            echo "NOT BACKED UP the VOLUME ==> $VOLUME <== in the MENU " >> $volume_log_file
        fi
    done
    for CONTAINER in $CONTAINERS
    do
       echo "========================================="
       echo "docker start ${CONTAINER}"
       docker start ${CONTAINER}
       echo "========================================="
    done
    VOLUME_BACKUP_LOG=$(cat $volume_log_file)
    # TERM=ansi whiptail --title "BACKUP VOLUMES STATUS" --infobox "$VOLUME_BACKUP_LOG" 40 115
    whiptail --title "BACKUP VOLUMES STATUS" --scrolltext --msgbox "$VOLUME_BACKUP_LOG" 40 115
    echo
    [ ! -f "$volume_log_file" ] && echo > /dev/null || rm -fv $volume_log_file
    echo
    find ${DIR}/backup-* -mtime +${ROTATE_DAYS} -exec rm -rvf {} \;
    clear
    echo
    cd $BDIR
    LIST_BACKUP
}
function VOLUME_LIST() {
    echo
    if [ -s $VOLUMES ]; then
        VOLUME_LIST_FILE=$( 
        echo "=================================================================="
        echo "========================== VOLUME LIST ==========================="
        echo "=================================================================="
        echo "`cat ${VOLUMES}`"
        echo "=================================================================="
        )
        # TERM=ansi whiptail --title "VOLUME LIST" --infobox "$VOLUME_LIST_FILE" 40 70
        whiptail --title "VOLUME LIST" --scrolltext --msgbox "$VOLUME_LIST_FILE" 40 70
        # sleep 3
        return 0
    else
        echo 
        # echo " VOLUMES File is empty "
        VOLUME_LIST_EMPTY=$(
        echo "========================================="
        echo "========= VOLUMES File is EMPTY ========="
        echo "========================================="
        )
        TERM=ansi whiptail --title " VOLUMES File is EMPTY" --infobox "VOLUME_LIST_EMPTY" 11 45
        sleep 5
        clear
        return 0
    fi
}
function LIST_BACKUP() {
    cd $DIR
    i=1
    declare -A FOLDER_SELECTION
    if [[ $(find ${DIR}/backup-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
        echo
        # echo "Location has no backups"
        LIST_BACKUP_EMPTY=$(
        echo "========================================="
        echo "======== Location has no backups ========"
        echo "========================================="
        )
        TERM=ansi whiptail --title "Location has no backups" --infobox "$LIST_BACKUP_EMPTY" 11 45
        sleep 3
        clear
        return 0
    fi
    echo
    LIST_BACKUP=$(
    echo "========================================="
    echo "========== ALL BACKUPS FOLDER ==========="
    echo "========================================="
    for folder in $(ls -td backup-*); do
        echo "[ ${i} ] - ${folder}"
        FOLDER_SELECTION[${i}]="${folder}"
        ((i++))
    done
    echo "========================================="
    )
    whiptail --title "ALL BACKUPS FOLDER" --scrolltext --msgbox "$LIST_BACKUP" 40 45
    cd $BDIR
    echo
    # sleep 1
}
function LIST_BACKUP_TREE() {
    cd $DIR
    if [[ $(find ${DIR}/backup-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
        echo
        # echo "Location has no backups"
        LIST_BACKUP_EMPTY=$(
        echo "========================================="
        echo "======== Location has no backups ========"
        echo "========================================="
        )
        TERM=ansi whiptail --title "Location has no backups" --infobox "$LIST_BACKUP_EMPTY" 11 45
        sleep 3
        clear
        return 0
    fi
    echo
    LIST_BACKUP=$(
    echo "========================================="
    echo "========== ALL BACKUPS FOLDER ==========="
    echo "========================================="
    tree -ar $DIR
    echo "========================================="
    )
    whiptail --title "ALL BACKUPS FOLDER" --scrolltext --msgbox "$LIST_BACKUP" 40 100
    cd $BDIR
    echo
}
function RESTORE_BACKUP() {
    # countdown 5
    # countdown5
    cd $DIR
    CONTAINERS=$(docker container ls --format 'table {{.Names}}' | tail -n +2)
    i=1
    declare -A FOLDER_SELECTION
    if [[ $(find ${DIR}/backup-* -maxdepth 1 -type d 2> /dev/null| wc -l) -lt 1 ]]; then
        TERM=ansi whiptail --title "Location has no Backups" --infobox "======== Location has no Backups ========" 11 45
        sleep 3
        clear
        return 0
    fi
    LIST_BACKUPS_FOLDER=$(
    echo "========================================="
    echo "========== ALL BACKUPS FOLDER ==========="
    echo "========================================="
    for folder in $(ls -td backup-*); do
        echo "[ ${i} ] - ${folder}"
        ((i++))
    done
    echo "========================================="
    )
    for folder in $(ls -td backup-*); do
        FOLDER_SELECTION[${i}]="${folder}"
        ((i++))
    done
    input_sel=0
    while [[ ${input_sel} -lt 1 ||  ${input_sel} -gt ${i} ]]; do
        input_sel=$(whiptail --title "ALL BACKUPS FOLDER" --inputbox "$LIST_BACKUPS_FOLDER" 40 45 3>&1 1>&2 2>&3)
        echo
        # echo "$input_sel"
        if [ -z "$input_sel" ]; then
            return 0
        else
            echo
        fi
        # LIST_BACKUPS=$(TERM=ansi whiptail --title "ALL BACKUPS FOLDER" --infobox "$LIST_BACKUPS_FOLDER  Select a restore point: " 50 45)
        # echo "$LIST_BACKUPS"
        # read -p " Select a restore point: " input_sel
        # echo "$input_sel"
    done
    echo
    RESTORE_POINT="${DIR}/${FOLDER_SELECTION[${input_sel}]}/"
    cd $RESTORE_POINT
    if [ "$(find $RESTORE_POINT -name "*.tgz" 2>/dev/null)" ]; then
        echo > /dev/null
    else
        TERM=ansi whiptail --title "NO TAR GZ FOUND" --infobox "============= Not .tgz found ============" 11 45
        sleep 3
        clear
        return 0
    fi
    # countdown5
    # countdown 5
    if whiptail --yesno "Do you want ALL DOCKER Volume delete befor RESTORE" 10 45; then
        DELETE_BEFOR_RESTORE
    else
        for CONTAINER in $CONTAINERS; do echo -e "\\ndocker stop ${CONTAINER}"; done
        for CONTAINER in $CONTAINERS
        do
            echo "========================================="
            echo " docker stop ${CONTAINER}"
            docker stop ${CONTAINER}
            echo "========================================="
        done
    fi
    volume_restor_log_file="$DIR/volume_restore_log_file.log"
    echo -n "" > $volume_restor_log_file
    for VOLUME in $(cat $VOLUMES)
    do
        VOLUMES_TGZ=$(find * -name "${VOLUME}.tgz" 2>/dev/null)
        if [[ ${VOLUME}.tgz = $VOLUMES_TGZ ]]; then
            echo "========================================="
            echo " Run restore for Docker volume $VOLUME"
            $VACKUP import $VOLUME.tgz $VOLUME
            echo " RESTORE The VOLUME ==> $VOLUME <== in the LIST " >> $volume_restor_log_file
            echo "========================================="
        else
            echo "========================================="
            echo " NOT FIND TGZ IN THE FOLDER FROM $VOLUME "
            echo " NOT FIND TGZ IN THE FOLDER FROM VOLUME ==> $VOLUME <== " >> $volume_restor_log_file
            echo " NOT RESTORE THE VOLUME ==================> $VOLUME <== in the LIST " >> $volume_restor_log_file
            echo "========================================="
        fi
    done
    echo
    for CONTAINER in $CONTAINERS
    do
        echo "========================================="
        echo " docker start ${CONTAINER}"
        docker start ${CONTAINER}
        echo "========================================="
    done
    clear
    VOLUME_RESTORE_LOG=$(cat $volume_restor_log_file)
    # TERM=ansi whiptail --title "RESTORE VOLUMES STATUS" --infobox "$VOLUME_RESTORE_LOG" 40 100
    sleep 3
    whiptail --title "RESTORE VOLUMES STATUS" --scrolltext --msgbox "$VOLUME_RESTORE_LOG" 40 100
    echo
    [ ! -f "$volume_restor_log_file" ] && echo > /dev/null || rm -fv $volume_restor_log_file
    cd $BDIR
    clear
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
    # countdown 10
    for CONTAINER in $CONTAINERS; do echo -e "\\ndocker stop ${CONTAINER}"; done
    for CONTAINER in $CONTAINERS
    do
        echo "========================================="
        echo " docker stop ${CONTAINER}"
        docker stop ${CONTAINER}
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
            echo "Successfully delete $VOLUME"
        fi
    done
}
function VOLUME_LIST_CREATE() {
    DOCKER_VOLUME_LS=$(docker volume ls  --format '{{.Name}}')
    if [[ -z $DOCKER_VOLUME_LS ]]; then
        # whiptail --title "NO DOCKER VOLUMES" --msgbox "NO DOCKER VOLUMES PRESENT" 8 29
        TERM=ansi whiptail --title "NO DOCKER VOLUMES" --infobox "NO DOCKER VOLUMES PRESENT" 8 29
        sleep 3
        clear
        return
    else
        echo > /dev/null
    fi
    i=1
    LIST_DOCKER_VOLUMES=$(
    for volume_ls in $DOCKER_VOLUME_LS; do
    echo "${i} ${volume_ls} OFF"
    ((i++))
    done
    )
    for volume_ls in $DOCKER_VOLUME_LS; do
        DOCKER_VOLUMES[${i}]="${volume_ls}"
        ((i++))
    done
    # echo "$LIST_DOCKER_VOLUMES"
    CHOICES=$(whiptail --separate-output --checklist "Choose options" 35 90 15 \
    `echo "$LIST_DOCKER_VOLUMES"` 3>&1 1>&2 2>&3)
    if [ -z "$CHOICES" ]; then
       clear
       return
    else
       echo "$CHOICES"
       echo -n "" > $VOLUMES
    fi
    sleep 2
    volume_log_file="$DIR/volume_log_file.log"
    echo -n "" > $volume_log_file
    for CHOICE_NUMBER in $CHOICES
    do
        VOLUME="${DOCKER_VOLUMES[${CHOICE_NUMBER}]}"
        DOCKER_VOLUME=$(docker volume ls  --format '{{.Name}}' | grep ${VOLUME}$)
        if [[ "$VOLUME" = "$DOCKER_VOLUME" ]]; then
            echo "========================================="
            echo "$VOLUME" >> $VOLUMES
            echo "CREATE VOLUME FROM CHOICE ==> $VOLUME <== in the MENU " >> $volume_log_file
            echo "========================================="
        else
            echo "ERROR CHOICE  ==> $VOLUME <== in the MENU " >> $volume_log_file
        fi
    done
    VOLUME_BACKUP_LOG=$(cat $volume_log_file)
    # TERM=ansi whiptail --title "BACKUP VOLUMES STATUS" --infobox "$VOLUME_BACKUP_LOG" 40 115
    whiptail --title "VOLUME LIST CREATE FROM MENU" --scrolltext --msgbox "$VOLUME_BACKUP_LOG" 40 115
    echo
    [ ! -f "$volume_log_file" ] && echo > /dev/null || rm -fv $volume_log_file
    echo
    find ${DIR}/backup-* -mtime +${ROTATE_DAYS} -exec rm -rvf {} \;
    clear
    VOLUME_LIST
}
function HELP() {
    HELP=$(
    echo "========================================="
    echo "================= HELP =================="
    echo "========================================="
    echo "========================================="
    echo "                                         "
    echo "============= COMING SOON ==============="
    echo "                                         "
    echo "========================================="
    echo "========================================="
    echo "========================================="
    )
    whiptail --title "HELP" --scrolltext --msgbox "$HELP" 20 45
    return 0
}
while [ true ];
do
CHOICE=$(
whiptail --title "DOCKER RESTORE MENU" --menu "Choose an option" 18 100 10 \
    "[ 1 ]" "BACKUP VOLUMES FROM FILE LIST" \
    "[ 2 ]" "BACKUP VOLUMES FROM MENU (docker volume ls)" \
    "[ 3 ]" "LIST ALL VOLUMES BACKUP" \
    "[ 4 ]" "RESTORE VOLUMES FROM FILE LIST" \
    "[ 5 ]" "VOLUME LIST FILE" \
    "[ 6 ]" "VOLUME CREATE LIST FILE FROM MENU" \
    "[ h ]" "HELP OUTPUT" \
    "[ e ]" "exit"  3>&1 1>&2 2>&3
)
    # usage;
    case $CHOICE in
        "[ 1 ]")
            BACKUP_VOLUMES
            ;;
        "[ 2 ]")
            BACKUP_VOLUMES_MENU
            ;;
        "[ 3 ]")
            LIST_BACKUP_TREE
            ;;
        "[ 4 ]")
            RESTORE_BACKUP
            ;;
        "[ 5 ]")
            VOLUME_LIST
            ;;
        "[ 6 ]")
            VOLUME_LIST_CREATE
            ;;
        # 5)
            # DELETE_BEFOR_RESTORE
            # ;;
        "[ h ]")
            HELP
            ;;
        "[ e ]")
            EXIT
            clear
            exit 1
            ;;
        *)
            clear
            break
            ;;
    esac
done
