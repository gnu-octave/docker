#!/bin/sh

## Helper script to build GNU Octave Docker images.

LOG_DIR=logs

OCTAVE_VERSIONS="\
  6.1.0 \
  5.2.0 \
  5.1.0 \
  4.4.1 \
  4.4.0 \
  4.2.2 \
  4.2.1 \
  4.2.0 \
  4.0.3 \
  4.0.2 \
  4.0.1 \
  4.0.0 "

## Detect supported container management tool.
if [ -x "$(command -v docker)" ]; then
  CONTAINER_CMD=docker
elif [ -x "$(command -v podman)" ]; then
  CONTAINER_CMD=podman
else
  echo "ERROR: Cannot find 'docker' or 'podman'."
  exit 1
fi

## Get credentials
source ./SECRETS

## Helper function to push a built image to DockerHub.
##   $DOCKERHUB_USERNAME see SECRETS
##   $DOCKERHUB_PASSWORD see SECRETS
##   $1                  image TAG
publish_image () {
  if [ ! -z "$DOCKERHUB_USERNAME" ]; then
    ${CONTAINER_CMD} login docker.io \
      --username ${DOCKERHUB_USERNAME} \
      --password ${DOCKERHUB_PASSWORD}
    ${CONTAINER_CMD} image push $1
  fi
}

## Helper function to push the build logs to some public web server.
##   $SCP_TARGET_DIR see SECRETS
##   $1              full path to a single log file
publish_log () {
  if [ ! -z "$SCP_TARGET_DIR" ]; then
    scp  $1  $SCP_TARGET_DIR
  fi
}

mkdir -p ${LOG_DIR}

## Save disk space and prune unused images.
## Octave builds really require lots of disk space!
${CONTAINER_CMD} image prune --force

## Build Octave build images.
## Currently not needed, DockerHub can build them :-)
for VER in #4 5 6
do
  TAG="docker.io/gnuoctave/octave-build:${VER}"
  echo "--------------------------------------------------"
  echo "-  Build ${TAG}"
  echo "--------------------------------------------------"
  LOG_FILE=${LOG_DIR}/$(date +%F_%H-%M)_build-oct-${VER}.log.txt
  ${CONTAINER_CMD} rmi ${TAG}
  ${CONTAINER_CMD} build \
    --no-cache \
    --file build-octave-${VER%%.*}.docker \
    --tag  ${TAG} \
    . 2>&1 | tee ${LOG_FILE}
  publish_log    ${LOG_FILE}
  publish_image  ${TAG}
done

## Build Octave images.
for VER in ${OCTAVE_VERSIONS}
do
  TAG="docker.io/gnuoctave/octave:${VER}"
  echo "--------------------------------------------------"
  echo "-  Build ${TAG}"
  echo "--------------------------------------------------"
  BUILD_VER=${VER%%.*}
  ## Exception, because of too old libraries.
  if [ "$VER" = "4.4.0" ] || [ "$VER" = "4.4.1" ]; then
    BUILD_VER=5
  fi
  LOG_FILE=${LOG_DIR}/$(date +%F_%H-%M)_oct-${VER}.log.txt
  ${CONTAINER_CMD} rmi ${TAG}
  ${CONTAINER_CMD} build \
    --no-cache \
    --file      octave-${BUILD_VER}.docker \
    --build-arg OCTAVE_VERSION=${VER} \
    --tag  ${TAG} \
    . 2>&1 | tee ${LOG_FILE}
  publish_log    ${LOG_FILE}
  publish_image  ${TAG}
done

## Build Octave JupyterLab image.
cd jupyterlab
VER="jupyterlab"
TAG="docker.io/gnuoctave/octave:${VER}"
echo "--------------------------------------------------"
echo "-  Build ${TAG}"
echo "--------------------------------------------------"
LOG_FILE=${LOG_DIR}/$(date +%F_%H-%M)_oct-${VER}.log.txt
${CONTAINER_CMD} rmi ${TAG}
${CONTAINER_CMD} build \
  --no-cache \
  --file Dockerfile \
  --tag  ${TAG} \
  . 2>&1 | tee ${LOG_FILE}
publish_log    ${LOG_FILE}
publish_image  ${TAG}
cd ..

## Save disk space and prune unused images.
## Octave builds really require lots of disk space!
${CONTAINER_CMD} image prune --force
