# Vackup: Manage Docker Volumes 

Vackup: (contraction of "volume backup")

Easily backup and restore Docker volumes using either tarballs or container images. It's designed for running from any host/container where you have the docker CLI.

Note that for open files like databases, it's usually better to use their prefered backup tool to create a backup file, but if you stored that file on a Docker volume, this could still be a way you get the Docker volume into a image or tarball for moving to remote storage for safe keeping.


`export`/`import` commands copy files between a local tarball and a volume. For making volume backups and restores.

`save`/`load` commands copy files between an image and a volume. For when you want to use image registries as a way to push/pull volume data.

Usage:

`vackup export VOLUME FILE`
  Creates a gzip'ed tarball in current directory from a volume

`vackup import FILE VOLUME`
  Extracts a gzip'ed tarball into a volume

`vackup save VOLUME IMAGE`
  Copies the volume contents to a busybox image in the /volume-data directory

`vackup load IMAGE VOLUME`
  Copies /volume-data contents from an image to a volume

