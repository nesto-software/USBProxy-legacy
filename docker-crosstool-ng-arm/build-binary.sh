#!/bin/bash
# ARG: $1 (KEEP_BUILD_CONTAINER_RUNNING): set to 1 to build and jump into the container afterwards
# ARG: $2 (TRANSFER_TO_PI_SSH_KEYFILE_PATH): set to ssh key which is used to upload the artifact on a rpi

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
if [ $? -ne 0 ]; then
  echo -e "\nWe MUST abort because docker build already failed and no new image was created!\n"
  exit 1;
fi

# we must create a container first to copy a file from the image
# see: https://stackoverflow.com/questions/25292198/docker-how-can-i-copy-a-file-from-an-image-to-a-host

# use the following to debug the container after successful docker build
if [ ! -z "$1" ] && [[ ( "$1" == 1 ) ]]; then
    echo -e "\nCommands to run in another shell:\n---------------------------------\nConnect: docker exec -it crosstool-builder bash\nKill: docker kill crosstool-builder\n"
    docker run --rm --name "${CONTAINER_NAME}" "${IMAGE_NAME}" tail -f /dev/null; exit
else
    docker run -d --rm --name "${CONTAINER_NAME}" "${IMAGE_NAME}" sleep 120 || echo "You can ignore that error message if you are running this script multiple times."
    #docker cp "${CONTAINER_NAME}:${BINARY_PATH}" "bin/usb-mitm"
    docker cp "${CONTAINER_NAME}:${STAGING_DIR}" "bin"
    (cd bin/staging; cp -r ../../../nodejs-client nodejs-client; tar cf ../../usb-mitm.tar .; rm -Rf nodejs-client)
    docker kill "${CONTAINER_NAME}"
fi

if [ ! -z "$2" ]; then
    scp -i "$2" ./usb-mitm.tar  pi@169.254.100.1:/home/pi/usb-mitm.tar
fi

# TODO: build deb package
# TODO: upload via aptly