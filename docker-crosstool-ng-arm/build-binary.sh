#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# build the docker container - use the name which is also generated by docker-compose
IMAGE_NAME=docker-crosstool-ng-arm_webapp:latest
CONTAINER_NAME=crosstool-builder
STAGING_DIR=/usr/raspberry-build/staging
BINARY_PATH=STAGING_DIR/bin/usb-mitm

# clear the binary output directory
mkdir -p "${DIR}/bin"
rm -Rf "${DIR}/bin/"*
rm usb-mitm.tar

docker build -t ${IMAGE_NAME} .

# we must create a container first to copy a file from the image
# see: https://stackoverflow.com/questions/25292198/docker-how-can-i-copy-a-file-from-an-image-to-a-host

# use the following to debug the container after successful docker build
#docker run --rm --name "${CONTAINER_NAME}" "${IMAGE_NAME}" tail -f /dev/null
docker run -d --rm --name "${CONTAINER_NAME}" "${IMAGE_NAME}" sleep 120 || echo "You can ignore that error message if you are running this script multiple times."
#docker cp "${CONTAINER_NAME}:${BINARY_PATH}" "bin/usb-mitm"
docker cp "${CONTAINER_NAME}:${STAGING_DIR}" "bin"
tar cf usb-mitm.tar bin/staging
docker kill "${CONTAINER_NAME}"

# TODO: build deb package
# TODO: upload via aptly