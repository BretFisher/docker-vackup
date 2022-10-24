# Vackup: Backup and Restore Docker Volumes

Vackup: (contraction of "volume backup")

Easily backup and restore Docker volumes using either tarballs or container images.
It's designed for running from any host/container where you have the docker CLI.

Note that for open files like databases,
it's usually better to use their preferred backup tool to create a backup file,
but if you stored that file on a Docker volume,
this could still be a way you get the Docker volume into a image or tarball
for moving to remote storage for safe keeping.

`export`/`import` commands copy files between a local tarball and a volume.
For making volume backups and restores.

`save`/`load` commands copy files between an image and a volume.
For when you want to use image registries as a way to push/pull volume data.

Usage:

`vackup export VOLUME FILE`
  Creates a gzip'ed tarball in current directory from a volume

`vackup import FILE VOLUME`
  Extracts a gzip'ed tarball into a volume

`vackup save VOLUME IMAGE`
  Copies the volume contents to a busybox image in the /volume-data directory

`vackup load IMAGE VOLUME`
  Copies /volume-data contents from an image to a volume

## Install

Download the `vackup` file in this repository to your local machine in your shell path and make it executable.

```shell
curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/vackup > /usr/local/bin/vackup
chmod +x /usr/local/bin/vackup
```


## Error conditions

If any of the commands fail, the script will check to see if a `VACKUP_FAILURE_SCRIPT`
environment variable is set.  If so it will run it and pass the line number the error
happened on and the exit code from the failed command.  Eg,

```shell
# /opt/bin/vackup-failed.sh
LINE_NUMBER=$1
EXIT_CODE=$2
send_slack_webhook "Vackup failed on line number ${LINE_NUMBER} with exit code ${EXIT_CODE}!"
```

```shell
export VACKUP_FAILURE_SCRIPT=/opt/bin/vackup-failed.sh
./vackup export ......
```

# Backup all volumes.
[⚠️ Don't forget to install vbackup first ⚠️](#install)

&nbsp;

Backup
```
for vmb in $(docker volume ls --format '{{.Name}}'); do vackup export $vmb ${vmb}.tgz ; done
```
Restore
```
for vmr in $(ls *.tgz); do vackup import $vmr ${vmr%%.*} ; done
```

&nbsp;

# Volume Backup Script from the a list and Restore Menu

<details>
<summary markdown="span">Volume Backup Script and Restore Menu</summary>

&nbsp;

## Volume List 

Make a volume list befor
```bash
mkdir -p /opt/backup-volume /opt/scripts && \
docker volume ls --format '{{.Name}}' > /opt/scripts/docker-volume-list.txt
```

Or Cchange the Variable in the Script it if you want something else
```txt
VOLUMES="/opt/scripts/docker-volume-list.txt"
DIR="/opt/backup-volume"
```

&nbsp;

##  Volume Backup single from the list
```bash
curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/scripts/docker-volume-backup-all.sh \
> /opt/scripts/docker-volume-backup-all.sh && chmod +x /opt/scripts/docker-volume-backup-all.sh
```

&nbsp;

## Volume Backup single from the list and Stop running Docker Container

```bash
curl -sSL \
https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/scripts/docker-stop-and-volume-backup-all.sh \
> /opt/scripts/docker-stop-and-volume-backup-all.sh && chmod +x /opt/scripts/docker-stop-and-volume-backup-all.sh
```

### FOR Crontab 
The Default ROTATE DAYS is 30 Days for delete the old Backups

Or Cchange the Variable in the Script it if you want something else
```txt
ROTATE_DAYS="30"
```
[Crontab Generator](https://crontab.guru/)
```txt
# Daily   AT 04:00 24H
00 04 * * * /opt/scripts/docker-stop-and-volume-backup-all.sh
# Weekly  AT 05:00 24H ON Monday
00 05 * * 1 /opt/scripts/docker-stop-and-volume-backup-all.sh
# Monthly AT 06:00 24H ON the first DAY on the Month.
00 06 1 * * /opt/scripts/docker-stop-and-volume-backup-all.sh

```

&nbsp;

## Volume Restore Menu
```bash
curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/scripts/docker-volume-restore-all.sh \
> /opt/scripts/docker-volume-restore-all.sh && chmod +x /opt/scripts/docker-volume-restore-all.sh
```

⚠️ Very Important ⚠️

The script is written to erase the contents of the volume before restoring it
<details>
<summary markdown="span">Usage DEMO</summary>

```txt
$ root@docker:/opt/scripts# ./docker-volume-restore-all.sh

=========================================
[ 1 ] - BACKUP VOLUMES
[ 2 ] - LIST ALL VOLUMES BACKUP
[ 3 ] - RESTORE VOLUMES BACKUP
[ 4 ] - VOLUME LIST FILE
[ h ] - HELP OUTPUT
[ e ] - exit
=========================================

Enter value: 2

=========================================
=========== ALL BACKUPS FOLDER ==========
=========================================
[ 1 ] - backup-2022-07-18--23-16
[ 2 ] - backup-2022-07-19--15-53
[ 3 ] - backup-2022-07-23--07-14
[ 4 ] - backup-2022-07-23--07-22
[ 5 ] - backup-2022-07-23--08-40
[ 6 ] - backup-2022-07-23--08-42
[ 7 ] - backup-2022-07-23--08-49
=========================================


=========================================
[ 1 ] - BACKUP VOLUMES
[ 2 ] - LIST ALL VOLUMES BACKUP
[ 3 ] - RESTORE VOLUMES BACKUP
[ 4 ] - VOLUME LIST FILE
[ h ] - HELP OUTPUT
[ e ] - exit
=========================================

Enter value: 4

=========================================
=============== VOLUME LIST =============
=========================================
pg-data
static-files
=========================================

=========================================
[ 1 ] - BACKUP VOLUMES
[ 2 ] - LIST ALL VOLUMES BACKUP
[ 3 ] - RESTORE VOLUMES BACKUP
[ 4 ] - VOLUME LIST FILE
[ h ] - HELP OUTPUT
[ e ] - exit
=========================================

Enter value: 5

=========================================
=========== Unknown parameter ===========
=========================================

$ root@docker:/opt/scripts#

```
</details>

&nbsp;

![DEMO GIF](/demo/demo-1.gif)

## Volume Restore Menu with Whiptail

```bash
curl -sSL https://raw.githubusercontent.com/alcapone1933/docker-vackup/master/scripts/docker-volume-restore-all-whiptail.sh \
> /opt/scripts/docker-volume-restore-all-whiptail.sh && chmod +x /opt/scripts/docker-volume-restore-all-whiptail.sh
```

### Usage DEMO

![DEMO GIF](/demo/demo-2.gif)

</details>

&nbsp;
