# Docker Vackup

Easily backup and restore docker volumes using either tarballs or container images


export/import copies files between a host tarball and a volume. For making
  volume backups and restores.

save/load copies files between an image and a volume. For when you want to use
  image registries as a way to push/pull volume data.

Usage:

`vackup export VOLUME FILE`
  Creates a gzip'ed tarball in current directory from a volume

`vackup import FILE VOLUME`
  Extracts a gzip'ed tarball into a volume

`vackup save VOLUME IMAGE`
  Copies the volume contents to a busybox image in the /volume-data directory

`vackup load IMAGE VOLUME`
  Copies /volume-data contents from an image to a volume

