#!/bin/bash
# Docker Volume File Backup and Restore Tool
# Easily tar up a volume on a local (or remote) engine
# Inspired by CLIP from Lukasz Lach

set -Eeo pipefail

handle_error() {
  exit_code=$?
  if [ -n "${VACKUP_FAILURE_SCRIPT}" ]; then
    /bin/bash "${VACKUP_FAILURE_SCRIPT}" "$1" $exit_code
  fi
  exit $exit_code
}

trap 'handle_error $LINENO' ERR

usage() {
cat <<EOF

"Docker Volume Backup". Replicates image management commands for volumes.

export/import copies files between a host tarball and a volume. For making
  volume backups and restores.

save/load copies files between an image and a volume. For when you want to use 
  image registries as a way to push/pull volume data.

Usage: 

vackup export VOLUME FILE
  Creates a gzip'ed tarball in current directory from a volume

vackup import FILE VOLUME
  Extracts a gzip'ed tarball into a volume

vackup save VOLUME IMAGE
  Copies the volume contents to a busybox image in the /volume-data directory

vackup load IMAGE VOLUME
  Copies /volume-data contents from an image to a volume

EOF
}

if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
    exit 0
fi

cmd_export() {
    VOLUME_NAME="$2"
    FILE_NAME="$3"
    
    if [ -z "$VOLUME_NAME" ] || [ -z "$FILE_NAME" ]; then
        echo "Error: Not enough arguments"
        usage
        exit 1
    fi
    
    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME";
    then
        echo "Error: Volume $VOLUME_NAME does not exist"
        exit 1
    fi

# TODO: check if file exists on host, if it does
# create a option for overwrite and check if that's set
# TODO: if FILE_NAME starts with / we need to error out
# unless we can translate full file paths

    if ! docker run --rm \
      -v "$VOLUME_NAME":/vackup-volume \
      -v "$(pwd)":/vackup \
      busybox \
      tar -zcvf /vackup/"$FILE_NAME" /vackup-volume;
    then
        echo "Error: Failed to start busybox backup container"
        exit 1
    fi

    echo "Successfully tar'ed volume $VOLUME_NAME into file $FILE_NAME"
}

cmd_import() {
    FILE_NAME="$2"
    VOLUME_NAME="$3"
    
    if [ -z "$VOLUME_NAME" ] || [ -z "$FILE_NAME" ]; then
        echo "Error: Not enough arguments"
        usage
        exit 1
    fi
    
    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME";
    then
        echo "Error: Volume $VOLUME_NAME does not exist"
        docker volume create "$VOLUME_NAME"
    fi

# TODO: check if file exists on host, if it does
# create a option for overwrite and check if that's set
# TODO: if FILE_NAME starts with / we need to error out
# unless we can translate full file paths    

    if ! docker run --rm \
      -v "$VOLUME_NAME":/vackup-volume \
      -v "$(pwd)":/vackup \
      busybox \
      tar -xvzf /vackup/"$FILE_NAME" -C /; 
    then
        echo "Error: Failed to start busybox container"
        exit 1
    fi

    echo "Successfully unpacked $FILE_NAME into volume $VOLUME_NAME"
}

cmd_save() {
    VOLUME_NAME="$2"
    IMAGE_NAME="$3"

    if [ -z "$VOLUME_NAME" ] || [ -z "$IMAGE_NAME" ]; then
        echo "Error: Not enough arguments"
        usage
        exit 1
    fi

    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME"; 
    then
        echo "Error: Volume $VOLUME_NAME does not exist"
        exit 1
    fi

    if ! docker run \
      -v "$VOLUME_NAME":/mount-volume \
      busybox \
      cp -Rp /mount-volume/. /volume-data/;
    then
        echo "Error: Failed to start busybox container"
        exit 1
    fi

    CONTAINER_ID=$(docker ps -lq)

    docker commit -m "saving volume $VOLUME_NAME to /volume-data" "$CONTAINER_ID" "$IMAGE_NAME"

    docker container rm "$CONTAINER_ID"
  
    echo "Successfully copied volume $VOLUME_NAME into image $IMAGE_NAME, under /volume-data"
}

cmd_load() {
    IMAGE_NAME="$2"
    VOLUME_NAME="$3"
    
    if [ -z "$VOLUME_NAME" ] || [ -z "$IMAGE_NAME" ]; then
        echo "Error: Not enough arguments"
        usage
        exit 1
    fi

    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME"; 
    then
      echo "Volume $VOLUME_NAME does not exist, creating..."
      docker volume create "$VOLUME_NAME"
    fi
    
    if ! docker run --rm \
      -v "$VOLUME_NAME":/mount-volume \
      "$IMAGE_NAME" \
      cp -Rp /volume-data/. /mount-volume/; 
    then
        echo "Error: Failed to start container from $IMAGE_NAME"
        exit 1
    fi

    echo "Successfully copied /volume-data from $IMAGE_NAME into volume $VOLUME_NAME"
}

COMMAND="$1"
case "$COMMAND" in
  export) cmd_export "$@" ;;
  import) cmd_import "$@" ;;
  save) cmd_save "$@" ;;
  load) cmd_load "$@" ;;
esac

exit 0
