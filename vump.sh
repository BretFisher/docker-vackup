#!/bin/bash


# Deine all spinnaker icons / colours
function stylesheet()
{
    TEXT_STONE_600='\e[38;2;87;83;78m'
    TEXT_ORANGE_500='\e[38;2;249;115;22m'
    TEXT_YELLOW_500='\e[38;2;234;179;8m'
    TEXT_GRAY_200='\e[38;2;229;231;235m'
    TEXT_GRAY_400='\e[38;2;156;163;175m'
    TEXT_GRAY_500='\e[38;2;107;114;128m'
    TEXT_GRAY_600='\e[38;2;75;85;99m'
    TEXT_GRAY_700='\e[38;2;55;65;81m'
    TEXT_VIOLET_500='\e[38;2;139;92;246m'
    TEXT_RED_500='\e[38;2;239;68;68m'
    TEXT_GREEN_500='\e[38;2;34;197;94m'
    TEXT_TEAL_500='\e[38;2;20;184;166m'
    TEXT_SKY_500='\e[38;2;14;165;233m'
    RESET_TEXT='\e[39m'
    ICON_FADE_200=░
    ICON_CMD=⌘
    ICON_ARROW_N=↑
    ICON_ARROW_S=↓
    ICON_CIRCLE=●
    BORDER_SKY_400='\e[38;2;56;189;248m'
    BORDER_EMERALD_400='\e[38;2;52;211;153m'
    BORDER_PINK_400='\e[38;2;244;114;182m'
    BORDER_ROSE_400='\e[38;2;251;113;133m'
    BORDER_FUCHSIA_400='\e[38;2;232;121;249m'
    BORDER_PURPLE_400='\e[38;2;192;132;252m'
    BORDER_INDIGO_400='\e[38;2;129;140;248m'
    BORDER_BLUE_400='\e[38;2;96;165;250m'
    BORDER_CYAN_400='\e[38;2;34;211;238m'
    BORDER_TEAL_400='\e[38;2;45;212;191m'
    BORDER_GREEN_400='\e[38;2;74;222;128m'
    BORDER_YELLOW_400='\e[38;2;250;204;21m'
    BORDER_ORANGE_400='\e[38;2;251;146;60m'
    BORDER_RED_400='\e[38;2;248;113;113m'
}

function mainmenu()
{
    
    # Run options with input values.
    MENU='
        {
        "select": {
            "heading": "'${TEXT_YELLOW_500}'Select the task to perform.",
            "clear": true,
            "clear_before_command": true,
            "icon": "ICON_FADE_200",
            "hide_message": true,
            "display_help": true,
            "reset_loop": false,
            "options": [
                {
                    "title": "🗄 Volume → 🗜 tar.gz",
                    "title_style": "",
                    "description": "Export contents of a docker volume into a tar.gz file in current directory on host.",
                    "description_style": "TEXT_GRAY_500",
                    "command": "cmd_export",
                    "bullet": "BORDER_SKY_400"
                },
                {
                    "title": "🗜 tar.gz → 🗄 Volume",
                    "title_style": "",
                    "description": "Import contents of a tar.gz file into a specific docker volume.",
                    "description_style": "TEXT_GRAY_500",
                    "command": "cmd_import",
                    "bullet": "BORDER_EMERALD_400"
                },
                {
                    "title": "🗄 Volume → 🏞 backup image",
                    "title_style": "",
                    "description": "Save contents of a docker volume into a docker container image ready to push to registry",
                    "description_style": "TEXT_GRAY_500",
                    "command": "cmd_save",
                    "bullet": "BORDER_PINK_400"
                },
                {
                    "title": "🏞 backup image → 🗄 Volume",
                    "title_style": "",
                    "description": "Load contents of backup docker image into a specific docker volume.",
                    "description_style": "TEXT_GRAY_500",
                    "command": "cmd_load",
                    "bullet": "BORDER_ROSE_400"
                },
                {
                    "title": "🛢 MySQL Container → 🏞 backup image",
                    "title_style": "",
                    "description": "Save MySQL dump on container to a backup image ready to push to a registry",
                    "description_style": "TEXT_GRAY_500",
                    "command": "cmd_dbsave",
                    "bullet": "BORDER_FUCHSIA_400"
                },
                {
                    "title": "🏞 backup image → 🛢 MySQL Container",
                    "title_style": "",
                    "description": "Load contents of a database backup image into a docker container MySQL database.",
                    "description_style": "TEXT_GRAY_500",
                    "command": "cmd_dbload",
                    "bullet": "BORDER_TEAL_400"
                }
            ]
        }
    }'
    menu "$MENU"

}



# ╭──────────────────────────────────────────────────────────╮
# │          Select a docker container from a list           │
# ╰──────────────────────────────────────────────────────────╯
function select_container()
{
    
    LIST_OF_CONTAINERS=$(docker container ls -a --format='{{.ID}} {{.Names}} {{.Image}}')

    MENU='
        {
        "select": {
            "heading": "'${BORDER_YELLOW_400}'Select the container.",
            "clear": true,
            "clear_before_command": true,
            "icon": "ICON_FADE_200",
            "hide_message": true,
            "display_help": true,
            "reset_loop": false,
            "options": ['

    LOOP=1
    while IFS= read -r line; do

        CONTAINER_ID=$(echo $line | head -n1 | cut -d " " -f1 | xargs )
        CONTAINER_NAME=$(echo $line | head -n1 | cut -d " " -f2 | xargs )
        CONTAINER_IMAGE=$(echo $line | head -n1 | cut -d " " -f3 | xargs )

        MENU+='
                {
                    "title": "'${CONTAINER_NAME}'",
                    "title_style": "",
                    "description": "'${TEXT_GRAY_700}${CONTAINER_ID}' '${TEXT_GRAY_600}${CONTAINER_NAME}'",
                    "description_style": "TEXT_GRAY_500",
                    "command": "CONTAINER=\"'${CONTAINER_NAME}'\" ",
                    "bullet": "BORDER_FUCHSIA_400"
                },'

        LOOP=$(( LOOP+1 ))
    done <<< "$LIST_OF_CONTAINERS"

    MENU+='
            ]
        }
    }'
    
    menu "$MENU"
}

# ╭──────────────────────────────────────────────────────────╮
# │             Select a docker volume from list             │
# ╰──────────────────────────────────────────────────────────╯
function select_volume()
{

    LIST_OF_VOLUMES=$(docker volume ls --format='{{lower .Name}} {{lower .Mountpoint}}')

    MENU='
        {
        "select": {
            "heading": "'${BORDER_YELLOW_400}'Select the Volume.",
            "clear": true,
            "clear_before_command": true,
            "icon": "ICON_FADE_200",
            "hide_message": true,
            "display_help": true,
            "reset_loop": false,
            "options": ['

    LOOP=1
    while IFS= read -r line; do

        VOLUME_NAME=$(echo $line | head -n1 | cut -d " " -f1 | xargs )
        VOLUME_MOUNTPOINT=$(echo $line | head -n1 | cut -d " " -f2 | xargs )

        MENU+='
                {
                    "title": "'${VOLUME_NAME}'",
                    "title_style": "",
                    "description": "Mountpoint: '${VOLUME_MOUNTPOINT}'",
                    "description_style": "TEXT_GRAY_500",
                    "command": "VOLUME=\"'${VOLUME_NAME}'\" ",
                    "bullet": "BORDER_SKY_400"
                },'

        LOOP=$(( LOOP+1 ))
    done <<< "$LIST_OF_VOLUMES"

    MENU+='
            ]
        }
    }'
    
    menu "$MENU"

}


# ╭──────────────────────────────────────────────────────────╮
# │              Select a docker image for list              │
# ╰──────────────────────────────────────────────────────────╯
function select_image()
{

    LIST_OF_IMAGES=$(docker image ls --format='{{lower .ID}} {{lower .Repository}} {{lower .Size}} {{lower .Tag}}')

    MENU='
        {
        "select": {
            "heading": "'${BORDER_YELLOW_400}'Select the Image.",
            "clear": true,
            "clear_before_command": true,
            "icon": "ICON_FADE_200",
            "hide_message": true,
            "display_help": true,
            "reset_loop": false,
            "options": ['

    LOOP=1
    while IFS= read -r line; do

        IMAGE_ID=$(echo $line | head -n1 | cut -d " " -f1 | xargs )
        IMAGE_REPOSITORY=$(echo $line | head -n1 | cut -d " " -f2 | xargs )
        IMAGE_SIZE=$(echo $line | head -n1 | cut -d " " -f3 | xargs )
        IMAGE_TAG=$(echo $line | head -n1 | cut -d " " -f4 | xargs )

        MENU+='
                {
                    "title": "'${IMAGE_REPOSITORY}'",
                    "title_style": "",
                    "description": "ID: '${TEXT_GRAY_500}${IMAGE_ID}${TEXT_GRAY_700}' TAG: '${TEXT_GRAY_500}${IMAGE_TAG}${TEXT_GRAY_700}' SIZE: '${TEXT_GRAY_500}${IMAGE_SIZE}${TEXT_GRAY_700}'",
                    "description_style": "TEXT_GRAY_700",
                    "command": "IMAGE=\"'${IMAGE_ID}'\" ",
                    "bullet": "TEXT_GREEN_500"
                },'

        LOOP=$(( LOOP+1 ))
    done <<< "$LIST_OF_IMAGES"

    MENU+='
            ]
        }
    }'
    
    menu "$MENU"
}


# ╭──────────────────────────────────────────────────────────╮
# │           Select a docker database from a list           │
# ╰──────────────────────────────────────────────────────────╯
function select_database()
{
    
    LIST_OF_DATABASES=$(docker exec db mysql -u$DB_USERNAME -p$DB_PASSWORD --silent --execute="show databases;")

    MENU='
        {
        "select": {
            "heading": "'${BORDER_YELLOW_400}'Select the container.",
            "clear": true,
            "clear_before_command": true,
            "icon": "ICON_FADE_200",
            "hide_message": true,
            "display_help": true,
            "reset_loop": false,
            "options": ['

    LOOP=1
    while IFS= read -r line; do

        MENU+='
                {
                    "title": "'${line}'",
                    "title_style": "",
                    "description": "Option '${LOOP}'",
                    "description_style": "TEXT_GRAY_500",
                    "command": "DB_DATABASE=\"'${line}'\" ",
                    "bullet": "BORDER_TEAL_400"
                },'

        LOOP=$(( LOOP+1 ))
    done <<< "$LIST_OF_DATABASES"

    MENU+='
            ]
        }
    }'
    
    menu "$MENU"
}


# ╭──────────────────────────────────────────────────────────╮
# │                      Ask a question                      │
# ╰──────────────────────────────────────────────────────────╯
function ask_question()
{
    clear
    QUESTION=$1

    printf "${BORDER_YELLOW_400}%s${RESET_TEXT}\n\n " "$QUESTION"

    printf "${TEXT_SKY_600}"
    read -p "${ICON_FADE_200} " ANSWER
    printf "${RESET_TEXT}\n"
}



# ╭──────────────────────────────────────────────────────────╮
# │                  Check Y/n to continue                   │
# ╰──────────────────────────────────────────────────────────╯
function confirmation()
{
    QUESTION=$1
    printf "${TEXT_AMBER_300}%s${RESET_TEXT}\n" "$QUESTION"
    read -r -p "Are you sure? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            CONFIRM="YES"
            ;;
        *)
            CONFIRM=""
            exit
            ;;
    esac
}

# ╭──────────────────────────────────────────────────────────╮
# │       Push the new image to the container registry       │
# ╰──────────────────────────────────────────────────────────╯
function push_to_registry()
{
    clear
    confirmation "Do you want to push container image to registry?"

    ask_question "specify tag to add to image. [default:latest]"
    if [ ! -z "${ANSWER}" ]; then
        TAG="$ANSWER"
    else
        TAG="latest"
    fi


    if ! docker image tag > /dev/null 2>&1;
    then
        printf "\n${TEXT_RED_500}Error: Failed to start busybox backup container"
        exit 1
    fi

    ask_question "specify the repository name in the registry."
    REPOSITORY="$ANSWER"

}

# ╭──────────────────────────────────────────────────────────╮
# │                          EXPORT                          │
# ╰──────────────────────────────────────────────────────────╯
#
# Copy files from a volume into a tar.gz file on the host.
# 
# 1. Create a BUSYBOX container
# 2. mount volume to    /vackup-volume
# 3. mount $pwd to      /vackup
# 4. create tar.gz of volume into $pwd
#                                ┌──────────────────────┐
# ┌────────────────┐             │ ┌────────────────┐   │
# │       ./       │────mount────┼▶│    /vackup     │   │
# └────────────────┘             │ └──────────────▲─┘   │
#                                │                │     │
#                                │ busybox       tar -c │
#                                │                │     │
# ┌────────────────┐             │ ┌──────────────┴─┐   │
# │     volume     │────mount────┼▶│ /vackup-volume │   │
# └────────────────┘             │ └────────────────┘   │
#                                └──────────────────────┘
function cmd_export() {

    select_volume "Select volume to EXPORT from"
    VOLUME_NAME="$VOLUME"
    ask_question "Filename to export to? "
    FILE_NAME="$ANSWER"

    # Add tar.gz on the end.
    if [[ ! $FILE_NAME == *.tar.gz ]]; then
        FILE_NAME="$FILE_NAME.tar.gz"
    fi

    # Check parameters are set
    if [ -z "$VOLUME_NAME" ] || [ -z "$FILE_NAME" ]; then
        printf "\n${TEXT_RED_500}Error: Not enough arguments"
        usage
        exit 1
    fi
    
    # Check docker volume exists
    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME" > /dev/null 2>&1;
    then
        printf "\n${TEXT_RED_500}Error: Volume $VOLUME_NAME does not exist"
        exit 1
    fi

    confirmation "You are going to export volume '${VOLUME_NAME}' to a file ${FILE_NAME}"
    
    spin "vump_export" "Exporting" "vump_export" 
}

function vump_export()
{
    if ! docker run --rm \
        -v "$VOLUME_NAME":/vackup-volume \
        -v "$(pwd)":/vackup \
        busybox \
        tar -zcvf /vackup/"$FILE_NAME" /vackup-volume > /dev/null 2>&1;
    then
        printf "\n${TEXT_RED_500}Error: Failed to start busybox backup container"
        exit 1
    fi

    printf "\n${TEXT_EMERALD_500}Successfully tar'ed volume $VOLUME_NAME into file $FILE_NAME ${RESET_TEXT}\n"
}



# ╭──────────────────────────────────────────────────────────╮
# │                          IMPORT                          │
# ╰──────────────────────────────────────────────────────────╯
# 
# Loads the contents of a backup tar.gz into a Volume.
#
# 1. Create a BUSYBOX container
# 2. mount volume to    /vackup-volume
# 3. mount $pwd to      /vackup
# 4. extract contents of tar.gz into volume
#
#                                ┌──────────────────────┐
# ┌────────────────┐             │ ┌────────────────┐   │
# │       ./       │────mount────┼▶│    /vackup     │   │
# └────────────────┘             │ └──────────────┬─┘   │
#                                │                │     │
#                                │ busybox       tar -x │
#                                │                │     │
# ┌────────────────┐             │ ┌──────────────▼─┐   │
# │     volume     │────mount────┼▶│ /vackup-volume │   │
# └────────────────┘             │ └────────────────┘   │
#                                └──────────────────────┘
#
function cmd_import() {

    ask_question "Filename to import from? "
    FILE_NAME="$ANSWER"

    select_volume "Select Volume to IMPORT into."
    VOLUME_NAME="$VOLUME"
    
    # Check parameters are set
    if [ -z "$VOLUME_NAME" ] || [ -z "$FILE_NAME" ]; then
        printf "\n${TEXT_RED_500}Error: Not enough arguments"
        usage
        exit 1
    fi
    
    # Check docker volume exists
    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME";
    then
        printf "\n${TEXT_RED_500}Error: Volume $VOLUME_NAME does not exist"
        docker volume create "$VOLUME_NAME"
    fi  

    confirmation "You are about to import the data in the file ${FILE_NAME} into the volume '${VOLUME_NAME}'"

    spin "vump_import" "Importing" "vump_import"
}

function vump_import()
{
    if ! docker run --rm \
        -v "$VOLUME_NAME":/vackup-volume \
        -v "$(pwd)":/vackup \
        busybox \
        tar -xvzf /vackup/"$FILE_NAME" -C /; 
    then
        printf "\n${TEXT_RED_500}Error: Failed to start busybox container"
        exit 1
    fi

    printf "${TEXT_EMERALD_500}Successfully unpacked $FILE_NAME into volume $VOLUME_NAME ${RESET_TEXT}\n"
}

# ╭──────────────────────────────────────────────────────────╮
# │                           SAVE                           │
# ╰──────────────────────────────────────────────────────────╯
#
# Save contents of a volume to a container image.
#
# 1. Mount volume to busybox
# 2. Copy contents to /volume-data/
# 3. Make an image of the container
# 4. Delete container
#
#                               ┌──────────────────────┐
# ┌────────────────┐            │  ┌────────────────┐  │
# │     volume     │────mount───┼─▶│ /vackup-volume │  │
# └────────────────┘            │  └──────────────┬─┘  │
#                               │                 │    │
#                               │ busybox      cp -Rp  │
#                               │                 │    │
#                               │ ┌───────────────▼┐   │
#                               │ │ /volume-data/  │   │
#                               │ └────────────────┘   │
#                               └──────────────────────┘
#                                           │           
#                                           ▼           
#                               ┌──────────────────────┐
#                               │  Image of Container  │
#                               └──────────────────────┘
#
function cmd_save() {

    select_volume "Select Volume to save into a backup image."
    VOLUME_NAME="$VOLUME"

    ask_question "Name to give backup image? "
    IMAGE_NAME="$ANSWER"

    # Check parameters are set
    if [ -z "$VOLUME_NAME" ] || [ -z "$IMAGE_NAME" ]; then
        printf "\n${TEXT_RED_500}Error: Not enough arguments"
        exit 1
    fi

    # Check docker volume exists
    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME"; 
    then
        printf "\n${TEXT_RED_500}Error: Volume $VOLUME_NAME does not exist"
        exit 1
    fi

    confirmation "You are about to save the data in the volume '${VOLUME_NAME}' into a container image called '${IMAGE_NAME}' "

    spin "vump_save" "Saving" "vump_save"
}

function vump_save()
{

    # Copy everything from volume to busybox container
    if ! docker run \
        -v "$VOLUME_NAME":/mount-volume \
        busybox \
        cp -Rp /mount-volume/. /volume-data/;
    then
        printf "\n${TEXT_RED_500}Error: Failed to start busybox container"
        exit 1
    fi

    # Get latest container ID (hash)
    CONTAINER_ID=$(docker ps -lq)

    # Create a new Image
    docker commit -m "saving volume $VOLUME_NAME to /volume-data" "$CONTAINER_ID" "$IMAGE_NAME"

    # Delete the container
    docker container rm "$CONTAINER_ID"

    printf "${TEXT_EMERALD_500}Successfully copied volume $VOLUME_NAME into image $IMAGE_NAME, under /volume-data ${RESET_TEXT}\n"

}

# ╭──────────────────────────────────────────────────────────╮
# │                           LOAD                           │
# ╰──────────────────────────────────────────────────────────╯
#
# Load contents of a container image into a Volume.
#
# 1. Create container of image
# 2. Mount volume to /mount-volume
# 3. Copy everything in /volume-data to /mount-volume
#
#                               ┌──────────────────────┐
# ┌────────────────┐            │  ┌────────────────┐  │
# │     volume     │────mount───┼─▶│ /mount-volume  │  │
# └────────────────┘            │  └──────────────▲─┘  │
#                               │                 │    │
#                               │ busybox      cp -Rp  │
#                               │                 │    │
#                               │ ┌───────────────┴┐   │
#                               │ │ /volume-data/  │   │
#                               │ └────────────────┘   │
#                               └──────────────────────┘
#                                           ▲           
#                                           │           
#                               ┌──────────────────────┐
#                               │  Image of Container  │
#                               └──────────────────────┘
#
cmd_load() {

    select_image "Select backup image to load data from."
    IMAGE_NAME="$IMAGE"

    select_volume "Select volume to load data into."
    VOLUME_NAME="$VOLUME"
    
    # Check parameters are set
    if [ -z "$VOLUME_NAME" ] || [ -z "$IMAGE_NAME" ]; then
        printf "\n${TEXT_RED_500}Error: Not enough arguments"
        usage
        exit 1
    fi

    # Check docker volume exists
    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME"; 
    then
        printf "Volume $VOLUME_NAME does not exist, creating..."
        docker volume create "$VOLUME_NAME"
    fi
    
    confirmation "You are about to load the contents of the container image called '${IMAGE_NAME}' into the volume '${VOLUME_NAME}'"

    spin "vump_load" "Loading" "vump_load"
}

function vump_load()
{
    # Copy everything from container into volume under /mount-volume
    if ! docker run --rm \
        -v "$VOLUME_NAME":/mount-volume \
        "$IMAGE_NAME" \
        cp -Rp /volume-data/. /mount-volume/; 
    then
        printf "\n${TEXT_RED_500}Error: Failed to start container from $IMAGE_NAME"
        exit 1
    fi

    printf "${TEXT_EMERALD_500}Successfully copied /volume-data from $IMAGE_NAME into volume $VOLUME_NAME ${RESET_TEXT}\n"
}










# ╭──────────────────────────────────────────────────────────╮
# │                          DBSAVE                          │
# ╰──────────────────────────────────────────────────────────╯
#
# Extracts the database from a Volume and creates a backup image
#
# 1. Run DB Container (with DB volume mounted)
# 2. MySQLDump database to current folder
# 3. Create new busybox container
# 4. Mount current dir to container
# 5. Copy dump file into container
# 6. Make image of container
#
#                                 ┌─────────────────────────┐
#                                 │     MySQL Container     │
# ┌──────────────────┐            │                         │
# │     DB Volume    │── mount ───┼───────▶ mysqldump       │
# └──────────────────┘            │             │           │
# ┌──────────────────┐            │ ┌───────────▼─────────┐ │
# │   ./backup.sql   │◀─── cp ────┼─│   /tmp/backup.sql   │ │
# └──────────────────┘            │ └─────────────────────┘ │
#           │                     └─────────────────────────┘
#           │                                                
#           │                     ┌─────────────────────────┐
#           │                     │         busybox         │
#           │                     │                         │
#           │                     │ ┌─────────────────────┐ │
#           └─────── mount ───────┼▶│ /vackup/backup.sql  │ │
#                                 │ └──────────┬──────────┘ │
#                                 │            │ cp -p      │
#                                 │            ▼            │
#                                 │ ┌─────────────────────┐ │
#                                 │ │ /db-data/backup.sql │ │
#                                 │ └─────────────────────┘ │
#                                 └─────────────────────────┘
#                                              │ commit      
#                                              ▼             
#                                  ┌──────────────────────┐  
#                                  │  Image of Container  │  
#                                  └──────────────────────┘  
#
function cmd_dbsave() {

    DB_USERNAME="root"

    select_container "Select MySQL Container to backup."
    CONTAINER="$CONTAINER"

    ask_question "Name to give backup image? "
    IMAGE_NAME="$ANSWER"

    ask_question "$DB_USERNAME database password? "
    DB_PASSWORD="$ANSWER"

    select_database "Select database to backup. "
    # ask_question "Name of database to backup? "
    DB_DATABASE="$DB_DATABASE"

    printf "${TEXT_GRAY_500}CONTAINER: ${TEXT_EMERALD_500}%s${RESET_TEXT}\n" "$CONTAINER"
    printf "${TEXT_GRAY_500}IMAGE_NAME: ${TEXT_EMERALD_500}%s${RESET_TEXT}\n" "$IMAGE_NAME"
    printf "${TEXT_GRAY_500}DB_DATABASE: ${TEXT_EMERALD_500}%s${RESET_TEXT}\n" "$DB_DATABASE"
    printf "${TEXT_GRAY_500}DB_USERNAME: ${TEXT_EMERALD_500}%s${RESET_TEXT}\n" "$DB_USERNAME"
    # printf "${TEXT_GRAY_500}DB_PASSWORD: ${TEXT_EMERALD_500}%s${RESET_TEXT}\n" "$DB_PASSWORD"
    printf "\n\n"

    # Check parameters are set
    if [ -z "$CONTAINER" ] || [ -z "$IMAGE_NAME" ] || [ -z "$DB_DATABASE" ] || [ -z "$DB_PASSWORD" ]; then
        printf "\n${TEXT_RED_500}Error: Not enough arguments"
        usage
        exit 1
    fi

    # Check docker container exists
    if ! docker ps -a | grep "$CONTAINER" > /dev/null 2>&1; 
    then
        printf "\n${TEXT_RED_500}Error: Container $CONTAINER does not exist"
        exit 1
    fi

    # Check docker container has mysql
    if ! docker exec $CONTAINER \
        mysqldump --version > /dev/null 2>&1; 
    then
        printf "\n${TEXT_RED_500}Error: Container $CONTAINER does not have a MySQL database"
        exit 1
    fi

    confirmation "You are about to create a backup of databse '${DB_DATABASE}' in container '${CONTAINER}' into an image called '${IMAGE_NAME}' "

    spin "vump_dbsave" "Loading" "vump_dbsave"
}

vump_dbsave()
{

    # Dump Database to /tmp
    if ! docker exec $CONTAINER \
        /bin/sh -c "mysqldump -u$DB_USERNAME -p$DB_PASSWORD --single-transaction $DB_DATABASE > /tmp/backup.sql";
    then
        printf "\n${TEXT_RED_500}Error: Failed to dump database to /tmp/backup.sql"
        exit 1
    fi

    # Copy backup file out of container
    if ! docker cp $CONTAINER:/tmp/backup.sql ./backup.sql;
    then
        printf "\n${TEXT_RED_500}Error: Unable to copy $CONTAINER:/tmp/backup.sql to current folder."
        exit 1
    fi

    # Copy backup.sql file to busybox container
    if ! docker run \
        -v "$(pwd)":/vackup \
        busybox \
        /bin/sh -c "mkdir -p /db-data/ && cp -p /vackup/backup.sql /db-data/backup.sql" ;
    then
        printf "\n${TEXT_RED_500}Error: Failed to start busybox container"
        exit 1
    fi

    # Get latest container ID (hash)
    CONTAINER_ID=$(docker ps -lq)

    # Create a new Image
    docker commit -m "saving DB from container $CONTAINER to /db-data/backup.sql" "$CONTAINER_ID" "$IMAGE_NAME"

    # Delete the container
    docker container rm "$CONTAINER_ID"

    printf "${TEXT_EMERALD_500}Successfully copied DB in container $CONTAINER into image $IMAGE_NAME, under /db-data${RESET_TEXT}\n"
}

# ╭──────────────────────────────────────────────────────────╮
# │                          DBLOAD                          │
# ╰──────────────────────────────────────────────────────────╯
#
# Loads a database from a backup image into a Volume.
#
# 1. Download DB data image
# 2. Copy the backup file out of image
# 3. Copy backup file into target container
# 4. Load backup into MySQL.
#
# ┌─────────────────────┐         ┌─────────────────────────┐
# │  Image with Backup  │────────▶│        Container        │
# └─────────────────────┘         │                         │
#                                 │ ┌─────────────────────┐ │
#                                 │ │ /db-data/backup.sql │ │
#                                 │ └─────────────────────┘ │
#                                 │            │            │
#                                 │            │  cp -p     │
#                                 │            ▼            │
# ┌───────────────────┐           │ ┌─────────────────────┐ │
# │        ./         │◀── mount ─┼─│/opt/mount/backup.sql│ │
# └───────────────────┘           │ └─────────────────────┘ │
#           │                     └─────────────────────────┘
#           │                                                
#           │                                                
#           │                     ┌─────────────────────────┐
#           │                     │     MySQL Container     │
#           │                     │ ┌─────────────────────┐ │
#           └───────cp────────────┼▶│   /tmp/backup.sql   │ │
#                                 │ └─────────────────────┘ │
#                                 │            │            │
#                                 │            │ mysql      │
#                                 │            ▼            │
# ┌──────────────────┐            │ ┌─────────────────────┐ │
# │     DB Volume    │◀──mounted──┼─│      DATABASE       │ │
# └──────────────────┘            │ └─────────────────────┘ │
#                                 └─────────────────────────┘
#
cmd_dbload() {

    select_image "Select database image to load data from. "
    IMAGE_NAME="$IMAGE"

    select_container "Select MySQL container to load data into. "
    TARGET_CONTAINER="$CONTAINER"

    ask_question "Name of database to load? "
    DB_DATABASE="$ANSWER"

    ask_question "$DB_USERNAME database password? "
    DB_PASSWORD="$ANSWER"

    printf "CONTAINER: %s\n" "$CONTAINER"
    printf "IMAGE_NAME: %s\n" "$IMAGE_NAME"
    printf "DB_DATABASE: %s\n" "$DB_DATABASE"
    printf "DB_USERNAME: %s\n" "$DB_USERNAME"
    printf "DB_PASSWORD: %s\n" "$DB_PASSWORD"

    # Check parameters are set
    if [ -z "$TARGET_CONTAINER" ] || [ -z "$IMAGE_NAME" ] || [ -z "$DB_DATABASE" ] || [ -z "$DB_PASSWORD" ]; then
        printf "\n${TEXT_RED_500}Error: Not enough arguments"
        usage
        exit 1
    fi

    confirmation "You are about to load the mysqldump file on the container image '${IMAGE_NAME}' into the database in the container '${CONTAINER}'"

    spin "vump_dbload" "Loading" "vump_dbload"
    
}

function vump_dbload()
{
    # Extract backup file out of image
    if ! docker run $PWD:/opt/mount --rm --entrypoint cp $IMAGE_NAME /db-data/backup.sql /opt/mount/backup.sql; 
    then
        printf "\n${TEXT_RED_500}Error: Could not copy backup.sql file from Image $IMAGE_NAME."
        exit 1
    fi
    
    # Copy backup file into container
    if ! docker cp ./backup.sql $TARGET_CONTAINER:/tmp/backup.sql ;
    then
        printf "\n${TEXT_RED_500}Error: Unable to copy backup.sql into $TARGET_CONTAINER:/tmp/backup.sql"
        exit 1
    fi

    # Load the Mysql Database
    if ! docker exec \
        $TARGET_CONTAINER \
        /bin/sh -c "cat /tmp/backup.sql | /usr/bin/mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > /dev/null 2>&1" ;
    then
        printf "\n${TEXT_RED_500}Error: Failed to load SQL file into database."
        exit 1
    fi

    printf "${TEXT_EMERALD_500}Successfully loaded the SQL file from the $IMAGE_NAME image, into the $TARGET_CONTAINER DB container.${RESET_TEXT}\n"
}








# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║                             START - JSON MENU CODE                           ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


function getkey {
    KEYSTRING=$(sed -e 's/\[/\"\,/g' -e 's/^\"\,/\[/g' -e 's/\]\./\,\"/g' -e 's/\./\"\,\"/g' -e '/^\[/! s/^/\[\"/g' -e '/\]$/! s/$/\"\]/g' <<< "$@")
    FOUT=$(grep -F "$KEYSTRING" <<< "$JSON_PARSED")
    FOUT="${FOUT#*$'\t'}"
    FOUT="${FOUT#*\"}"
    FOUT="${FOUT%\"*}"
    echo "$FOUT"
}

function getarrlen {
    KEYSTRING=$(sed -e '/^\[/! s/\[/\"\,/g' -e 's/\]\./\,\"/g' -e 's/\./\"\,\"/g' -e '#^$#! {/^\[/! s/^/\[\"/g}' -e '/^$/! s/$/\"\,/g' -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' -e 's/\,/\\\,/g' -e '/^$/ s/^/\\\[/g' <<< "$@")
    LEN=$(grep -o "${KEYSTRING}[0-9]*" <<< "$JSON_PARSED" | tail -n -1 | grep -o "[0-9]*$")
    if [ -n "$LEN" ]; then
        LEN=$(($LEN+1))
    else
        LEN="0"
    fi
    echo "$LEN"
}


function parse_classes()
{
    PREFIX=$1

    CLASSES=$2
    export IFS=" "
    for CLASS in $CLASSES; do

        IFS="_" read PARAMETER PRIMARY SECONDARY <<< "$CLASS"

        if  [[ $PARAMETER == 'TEXT' ]] || 
            [[ $PARAMETER == 'BG' ]] || 
            [[ $PARAMETER == 'BORDER' ]]; then
            export declare "${PREFIX}_${PARAMETER}_COLOUR"=${!CLASS}
        fi
        if  [[ $PARAMETER == PX* ]] || 
            [[ $PARAMETER == PY* ]] || 
            [[ $PARAMETER == PT* ]] || 
            [[ $PARAMETER == PR* ]] || 
            [[ $PARAMETER == PB* ]] || 
            [[ $PARAMETER == PL* ]]; then

            export declare "${PREFIX}_$PARAMETER"=${!CLASS}
        fi 
        if  [[ $PARAMETER == EDGE* ]] && [[ $SECONDARY == "" ]] ; then
            VAR="${PARAMETER}_${PRIMARY}_TL"; export declare "${PREFIX}_${PARAMETER}_TL"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_T";  export declare "${PREFIX}_${PARAMETER}_T"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_TR"; export declare "${PREFIX}_${PARAMETER}_TR"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_R";  export declare "${PREFIX}_${PARAMETER}_R"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_BR"; export declare "${PREFIX}_${PARAMETER}_BR"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_B";  export declare "${PREFIX}_${PARAMETER}_B"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_BL"; export declare "${PREFIX}_${PARAMETER}_BL"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_L";  export declare "${PREFIX}_${PARAMETER}_L"=${!VAR}
        fi 
        if [[ $PARAMETER == EDGE* ]] && ! [[ $SECONDARY == "" ]] ; then
            VAR="${CLASS}"; export declare "${PREFIX}_${PARAMETER}_${SECONDARY}"=${!VAR}
        fi
        if  [[ $PARAMETER == 'W' ]]; then
            export declare "${PREFIX}_${PARAMETER}"=${!CLASS}
        fi    
        
        if  [[ $PARAMETER == 'H' ]]; then
            export declare "${PREFIX}_${PARAMETER}"=${!CLASS}
        fi
        if  [[ $PARAMETER == 'ALIGN' ]]; then
            export declare "${PREFIX}_${PARAMETER}"=${!CLASS}
        fi

    done
}


function select_option {
    
    HEIGHT=3
    FOOTER_HEIGHT=2

    ESC=$( printf "\033")                                                               
    cursor_blink_on()  { printf "$ESC[?25h"; }                                          
    cursor_blink_off() { printf "$ESC[?25l"; }                                          
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }                                   
    
    ref_to_content()   {
        VARNAME=$1
        REFERENCE=${!VARNAME}
        echo "${REFERENCE}"
    }

    ref_to_ref_to_content()   {
        VARNAME=$1
        REFERENCE=${!VARNAME}
        OUTPUT=${!REFERENCE}
        echo "${OUTPUT}"
    }

    print_option()     {                                                                
        TEXT=$1
        LOOP_INDEX=$2

        TITLE=$( ref_to_content "SELECT_ARRAY_TITLE_${LOOP_INDEX}" )
        TITLE_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_TITLE_STYLE_${LOOP_INDEX}")
        DESCRIPTION=$(ref_to_content "SELECT_ARRAY_DESCRIPTION_${LOOP_INDEX}")
        DESCRIPTION_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_DESCRIPTION_STYLE_${LOOP_INDEX}")

        TITLE=$(eval "printf \"${TITLE}\"")
        DESCRIPTION=$(eval "printf \"${DESCRIPTION}\"")

        OPTION_TEXT=''
        OPTION_TEXT+="  "
        OPTION_TEXT+="${TITLE_STYLE}"
        OPTION_TEXT+="${TITLE}\n"
        OPTION_TEXT+="${RESET_TEXT}"
        OPTION_TEXT+="  "
        OPTION_TEXT+="${DESCRIPTION_STYLE}"
        OPTION_TEXT+="${DESCRIPTION}"
        OPTION_TEXT+="${RESET_ALL}"

        printf "$OPTION_TEXT"; 
    }               

    invert_selected()  {                                                                
        TEXT=$1
        LOOP_INDEX=$2

        TITLE=$( ref_to_content "SELECT_ARRAY_TITLE_${LOOP_INDEX}" )
        TITLE_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_TITLE_STYLE_${LOOP_INDEX}")
        DESCRIPTION=$(ref_to_content "SELECT_ARRAY_DESCRIPTION_${LOOP_INDEX}")
        DESCRIPTION_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_DESCRIPTION_STYLE_${LOOP_INDEX}")
        SIDEBAR_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_SIDEBAR_STYLE_${LOOP_INDEX}")
        SIDEBAR_ICON=$(ref_to_content "$SELECT_ARRAY_SIDEBAR_ICON")

        TITLE=$(eval "printf \"${TITLE}\"")
        DESCRIPTION=$(eval "printf \"${DESCRIPTION}\"")

        OPTION_TEXT=''
        OPTION_TEXT+="${SIDEBAR_STYLE}"
        OPTION_TEXT+="${SIDEBAR_ICON} "
        OPTION_TEXT+="${TITLE_STYLE}"
        OPTION_TEXT+="${TITLE}\n"
        OPTION_TEXT+="${RESET_TEXT}"
        OPTION_TEXT+="${SIDEBAR_STYLE}"
        OPTION_TEXT+="${SIDEBAR_ICON} "
        OPTION_TEXT+="${DESCRIPTION_STYLE}"
        OPTION_TEXT+="${DESCRIPTION}"
        OPTION_TEXT+="${RESET_ALL}"

        printf "$OPTION_TEXT"; 

    }                                  

    get_terminal_height()   {                                                           
        IFS=';'                                                                         
        read -sdR -p $'\E[6n' ROW COL;                                                  
        echo ${ROW#*[};                                                                 
    }             

    key_input()        
    { 
        read -s -n3 key 2>/dev/null >&2                                
        if [[ $key = $ESC[A ]]; then echo up;    fi                 
        if [[ $key = $ESC[B ]]; then echo down;  fi                 
        if [[ $key = ""     ]]; then echo enter; fi; 
    }              

    NEWLINE_COUNT=$(( ( $# * $HEIGHT ) ))
    for (( c=1; c<=$NEWLINE_COUNT; c++)) ; do printf "\n" ; done

    local lastrow=$(get_terminal_height)                                               
    TOTAL_LINES=$(( $# * $HEIGHT ))                                                     
    local STARTING_ROW=$(( $lastrow - $TOTAL_LINES ))                                  
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2                              
    cursor_blink_off                                                                    

    local selected=0                                                                    
    while true; do                                                                     

            local LINE_OFFSET=0                                                               

            for opt; do                                                                       

                cursor_to $(( $STARTING_ROW + $LINE_OFFSET )) 0                               

                if [ $LINE_OFFSET -eq $(( $selected * $HEIGHT)) ]; then                       
                    invert_selected "$opt" "$selected"                                        
                else
                    INDEX=$(( $LINE_OFFSET / $HEIGHT ))
                    print_option "$opt" "$INDEX"                                              
                fi
                (( LINE_OFFSET = LINE_OFFSET + $HEIGHT  ))                                    
            done

            case `key_input` in                                                               
                enter) break;;                                                                

                up)    ((selected = selected - 1)); 
                    if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;                   

                down)  ((selected = selected + 1));                                           
                    if [ $selected -ge $# ]; then selected=0; fi;;                            
            esac

    done

    cursor_to $lastrow                                                                        
    printf "\n"
    cursor_blink_on

    return $selected
}



function parse_json()
{

    throw() {
        echo "$*" >&2
        exit 1
    }

    BRIEF=0
    LEAFONLY=0
    PRUNE=0
    NO_HEAD=0
    NORMALIZE_SOLIDUS=0

    parse_options() {

        set -- "$@"
        local ARGN=$#
        while [ "$ARGN" -ne 0 ]
        do
        case $1 in
            -b) BRIEF=1
                LEAFONLY=1
                PRUNE=1
            ;;
            -l) LEAFONLY=1
            ;;
            -p) PRUNE=1
            ;;
            -n) NO_HEAD=1
            ;;
            -s) NORMALIZE_SOLIDUS=1
            ;;
            ?*) echo "ERROR: Unknown option."
                exit 0
            ;;
        esac
        shift 1
        ARGN=$((ARGN-1))
        done
    }

    awk_egrep () {
        local pattern_string=$1

        gawk '{
        while ($0) {
            start=match($0, pattern);
            token=substr($0, start, RLENGTH);
            print token;
            $0=substr($0, start+RLENGTH);
        }
        }' pattern="$pattern_string"
    }

    tokenize () {
        local GREP
        local ESCAPE
        local CHAR

        if echo "test string" | egrep -ao --color=never "test" >/dev/null 2>&1
        then
        GREP='egrep -ao --color=never'
        else
        GREP='egrep -ao'
        fi

        if echo "test string" | egrep -o "test" >/dev/null 2>&1
        then
        ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
        CHAR='[^[:cntrl:]"\\]'
        else
        GREP=awk_egrep
        ESCAPE='(\\\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
        CHAR='[^[:cntrl:]"\\\\]'
        fi

        local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
        local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
        local KEYWORD='null|false|true'
        local SPACE='[[:space:]]+'

        local is_wordsplit_disabled=$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')
        if [ $is_wordsplit_disabled != 0 ]; then setopt shwordsplit; fi
        $GREP "$STRING|$NUMBER|$KEYWORD|$SPACE|." | egrep -v "^$SPACE$"
        if [ $is_wordsplit_disabled != 0 ]; then unsetopt shwordsplit; fi
    }

    parse_array () {
        local index=0
        local ary=''
        read -r token
        case "$token" in
        ']') ;;
        *)
            while :
            do
            parse_value "$1" "$index"
            index=$((index+1))
            ary="$ary""$value" 
            read -r token
            case "$token" in
                ']') break ;;
                ',') ary="$ary," ;;
                *) throw "EXPECTED , or ] GOT ${token:-EOF}" ;;
            esac
            read -r token
            done
            ;;
        esac
        [ "$BRIEF" -eq 0 ] && value=$(printf '[%s]' "$ary") || value=
        :
    }

    parse_object () {
        local key
        local obj=''
        read -r token
        case "$token" in
        '}') ;;
        *)
            while :
            do
            case "$token" in
                '"'*'"') key=$token ;;
                *) throw "EXPECTED string GOT ${token:-EOF}" ;;
            esac
            read -r token
            case "$token" in
                ':') ;;
                *) throw "EXPECTED : GOT ${token:-EOF}" ;;
            esac
            read -r token
            parse_value "$1" "$key"
            obj="$obj$key:$value"        
            read -r token
            case "$token" in
                '}') break ;;
                ',') obj="$obj," ;;
                *) throw "EXPECTED , or } GOT ${token:-EOF}" ;;
            esac
            read -r token
            done
        ;;
        esac
        [ "$BRIEF" -eq 0 ] && value=$(printf '{%s}' "$obj") || value=
        :
    }

    parse_value () {
        local jpath="${1:+$1,}$2" isleaf=0 isempty=0 print=0
        case "$token" in
        '{') parse_object "$jpath" ;;
        '[') parse_array  "$jpath" ;;
        ''|[!0-9]) throw "EXPECTED value GOT ${token:-EOF}" ;;
        *) value=$token
            [ "$NORMALIZE_SOLIDUS" -eq 1 ] && value=$(echo "$value" | sed 's#\\/#/#g')
            isleaf=1
            [ "$value" = '""' ] && isempty=1
            ;;
        esac
        [ "$value" = '' ] && return
        [ "$NO_HEAD" -eq 1 ] && [ -z "$jpath" ] && return

        [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 0 ] && print=1
        [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && [ $PRUNE -eq 0 ] && print=1
        [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 1 ] && [ "$isempty" -eq 0 ] && print=1
        [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && \
        [ $PRUNE -eq 1 ] && [ $isempty -eq 0 ] && print=1
        [ "$print" -eq 1 ] && printf "[%s]\t%s\n" "$jpath" "$value"
        :
    }

    parse () {
        read -r token
        parse_value
        read -r token
        case "$token" in
        '') ;;
        *) throw "EXPECTED EOF GOT $token" ;;
        esac
    }

        parse_options "$@"
        tokenize | parse

}


function menu(){

    CONFIG_FILE=$1
    JSON_PARSED=$(echo $MENU | parse_json -l)
    JSON_SELECT_LENGTH=$(getarrlen select.options)
    HEADING=$(getkey select.heading)
    CLEAR_SCREEN=$(getkey select.clear)
    CLEAR_BEFORE_COMMAND_SCREEN=$(getkey select.clear_before_command)
    declare SELECT_ARRAY_SIDEBAR_ICON=$(getkey select.icon)
    HIDE_MESSAGE=$(getkey select.hide_message)
    DISPLAY_HELP=$(getkey select.display_help)
    RESET_LOOP=$(getkey select.reset_loop)

    if $CLEAR_SCREEN; then clear; fi

    SELECT_ARRAY=()
    for (( LOOP=0; LOOP<${JSON_SELECT_LENGTH}; LOOP++ ))
    do 

        declare LOOP_SELECT_INDEX=$LOOP
        declare LOOP_SELECT_TITLE=$(getkey select.options[$LOOP].title)
        declare LOOP_SELECT_TITLE_STYLE=$(getkey select.options[$LOOP].title_style)
        declare LOOP_SELECT_DESCRIPTION=$(getkey select.options[$LOOP].description)
        declare LOOP_SELECT_DESCRIPTION_STYLE=$(getkey select.options[$LOOP].description_style)
        declare LOOP_SELECT_COMMAND=$(getkey select.options[$LOOP].command)
        declare LOOP_SELECT_HEIGHT=$(getkey select.options[$LOOP].height)
        declare LOOP_SELECT_SIDEBAR_STYLE=$(getkey select.options[$LOOP].bullet)

        LOOP_SELECT_COMMAND=${LOOP_SELECT_COMMAND//\\/}  

        TITLE_STYLE_TEXT_COLOUR="${TEXT_GRAY_100}"
        DESCRIPTION_STYLE_TEXT_COLOUR="${TEXT_GRAY_400}"
        SIDELINE_STYLE_BORDER_COLOUR="${BORDER_GRAY_900}"

        parse_classes "TITLE_STYLE" "${LOOP_SELECT_TITLE_STYLE}"
        parse_classes "DESCRIPTION_STYLE" "${LOOP_SELECT_DESCRIPTION_STYLE}"

        SELECT_ARRAY+=("")

        declare SELECT_ARRAY_INDEX_$LOOP="${LOOP_SELECT_INDEX}"
        declare SELECT_ARRAY_TITLE_$LOOP="${LOOP_SELECT_TITLE}"
        declare SELECT_ARRAY_TITLE_STYLE_$LOOP="${LOOP_SELECT_TITLE_STYLE}"
        declare SELECT_ARRAY_DESCRIPTION_$LOOP="${LOOP_SELECT_DESCRIPTION}"
        declare SELECT_ARRAY_DESCRIPTION_STYLE_$LOOP="${LOOP_SELECT_DESCRIPTION_STYLE}"
        declare SELECT_ARRAY_COMMAND_$LOOP="${LOOP_SELECT_COMMAND}"
        declare SELECT_ARRAY_HEIGHT_$LOOP="${LOOP_SELECT_HEIGHT}"
        declare SELECT_ARRAY_SIDEBAR_STYLE_$LOOP="${LOOP_SELECT_SIDEBAR_STYLE}"

    done

    if $DISPLAY_HELP; then
        printf "$TEXT_STONE_500 $ICON_ARROW_N $TEXT_STONE_600 up $ICON_CIRCLE $TEXT_STONE_500 $ICON_ARROW_S $TEXT_STONE_600 down $ICON_CIRCLE $TEXT_STONE_500 enter $TEXT_STONE_600 choose $RESET_TEXT\n\n";
    fi

    printf "$HEADING\n\n"

    select_option "${SELECT_ARRAY[@]}"
    choice=$?

    COMMAND_NAME="SELECT_ARRAY_COMMAND_$choice"
    COMMAND="${!COMMAND_NAME}"

    if ! $HIDE_MESSAGE; then
        printf '%s' "Running command:${TEXT_EMERALD_300} ${COMMAND} ${RESET_TEXT}"
    fi

    if $CLEAR_BEFORE_COMMAND_SCREEN; then clear; fi
    eval "${COMMAND}"

    if $RESET_LOOP; then
        options $@
    fi

}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║                             END - JSON MENU CODE                             ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function spin()
{
    tput civis

    # Clear Line
    CL="\e[2K"
    # Spinner Character
    SPINNER="𛰀𛱃𛱄𛱅○𛱅𛱄𛱃𛰀"

    function spinner() {
        TASK=$1
        MESSAGE=$2
        while :; do
            jobs %1 > /dev/null 2>&1 
            [ $? = 0 ] || {
                printf "${TEXT_EMERALD_500}${ICON_TICK}${RESET_ALL} ${TASK} ${TEXT_EMERALD_500}Done${RESET_ALL}\n"
                break
            }

            if [ $? -ne 0 ]; then
                printf "${TEXT_RED_500}${ICON_CROSS}${RESET_ALL} ${TASK} ${TEXT_RED_500}Failed${RESET_ALL}\n"
                break
            fi

            for (( i=0; i<${#SPINNER}; i++ )); do
                sleep 0.05
                printf "${TEXT_AMBER_500}${SPINNER:$i:1}${RESET_ALL} ${TASK} ${TEXT_AMBER_500}${MESSAGE}${RESET_ALL}\r"
            done
        done
    }

    MESSAGE="${2-InProgress}"
    TASK="${3-$1}"

    if [[ ! -z "${4}" ]]; then
        SPINNER=$(echo -n "${4//[[:space:]]/}")
    fi

    if [[ ! -z "${5}" ]]; then
        $1 > /dev/null 2>&1 & spinner "$TASK" "$MESSAGE"
    else
        $1 & spinner "$TASK" "$MESSAGE"
    fi

    tput cnorm
}


stylesheet
mainmenu