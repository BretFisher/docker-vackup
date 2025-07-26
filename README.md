# Vackup: Backup and Restore Docker Volumes

[![Lint Code Base](https://github.com/BretFisher/docker-vackup/actions/workflows/linter.yml/badge.svg)](https://github.com/BretFisher/docker-vackup/actions/workflows/linter.yml)
[![Test Vackup](https://github.com/BretFisher/docker-vackup/actions/workflows/test.yml/badge.svg)](https://github.com/BretFisher/docker-vackup/actions/workflows/test.yml)
[![CI](https://github.com/BretFisher/docker-vackup/actions/workflows/ci.yml/badge.svg)](https://github.com/BretFisher/docker-vackup/actions/workflows/ci.yml)

**This is now built into Docker Desktop's Dashboard UI ([Volumes Tab](https://docs.docker.com/desktop/use-desktop/volumes/)) which has more features, but I'll keep this tool around for those not using Docker Desktop.**

Vackup: (contraction of "volume backup")

Easily backup and restore Docker volumes using either tarballs or container images.
It's designed for running from any host/container where you have the Docker CLI.

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
sudo curl -sSL https://raw.githubusercontent.com/BretFisher/docker-vackup/main/vackup -o /usr/local/bin/vackup && sudo chmod +x /usr/local/bin/vackup
```

## Testing

Vackup includes a comprehensive test suite using [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core) 
that ensures compatibility across macOS, Linux, and Windows WSL.

### Run Tests Locally

```shell
# Install Bats first
# macOS: brew install bats-core
# Ubuntu/Debian: apt-get install bats

# Run all tests
./test/run-tests.sh

# Run with verbose output
./test/run-tests.sh -v

# Clean up test resources first
./test/run-tests.sh -c
```

### Test Coverage

- All four commands (`export`, `import`, `save`, `load`)
- Error handling and edge cases
- Cross-platform compatibility
- Data integrity and round-trip consistency
- Files with special characters and complex directory structures

See [`test/README.md`](test/README.md) for detailed testing documentation.

## Error conditions

If any of the commands fail, the script will check to see if a `VACKUP_FAILURE_SCRIPT`
environment variable is set. If so it will run it and pass the line number the error
happened on and the exit code from the failed command. Eg,

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
