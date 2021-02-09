#!/bin/sh

## Helper script to build GNU Octave Docker versions.

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
##   $SCP_CMD see SECRETS
##   $1       full path to a single log file
publish_log () {
  if [ ! -z "$SCP_CMD" ]; then
    $SCP_CMD $1
  fi
}

mkdir -p ${LOG_DIR}

## Build build images
## Currently not needed, DockerHub can build them
for VER in #4 5 6
do
  TAG="docker.io/gnuoctave/octave-build:${VER}"
  echo "--------------------------------------------------"
  echo "-  Build ${TAG}"
  echo "--------------------------------------------------"
  LOG_FILE=${LOG_DIR}/$(date +%F_%H-%M)_build-oct-${VER}.log.html
  printf "<pre>\n"          >> ${LOG_FILE}
  ${CONTAINER_CMD} build \
    --file build-octave-${VER%%.*}.docker \
    --tag  ${TAG} . 2>&1 | tee ${LOG_FILE}
  printf "</pre>\n"         >> ${LOG_FILE}
  publish_image ${TAG}
  publish_log   ${LOG_FILE}
done

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
  LOG_FILE=${LOG_DIR}/$(date +%F_%H-%M)_oct-${VER}.log.html
  printf "<pre>\n"          >> ${LOG_FILE}
  ${CONTAINER_CMD} build \
    --file      octave-$BUILD_VER.docker \
    --build-arg OCTAVE_VERSION=${VER} \
    --tag  ${TAG} . 2>&1 | tee ${LOG_FILE}
  printf "</pre>\n"         >> ${LOG_FILE}
  publish_image ${TAG}
  publish_log   ${LOG_FILE}
done
