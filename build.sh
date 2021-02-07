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

mkdir -p ${LOG_DIR}

## Build build images
## Currently not needed, DockerHub can build them
for VER in #4 5 6
do
  TAG="docker.io/gnuoctave/octave-build:${VER}"
  echo "--------------------------------------------------"
  echo "-  Build ${TAG}"
  echo "--------------------------------------------------"
  ${CONTAINER_CMD} build \
    --file build-octave-${VER%%.*}.docker \
    --tag  ${TAG} \
    . 2>&1 | tee ${LOG_DIR}/build-oct-${VER}-$(date +%F_%H-%M-%S).log.txt
  ${CONTAINER_CMD} login docker.io \
    --username ${USERNAME} \
    --password ${PASSWORD}
  ${CONTAINER_CMD} image push ${TAG}
done

for VER in ${OCTAVE_VERSIONS}
do
  TAG="docker.io/gnuoctave/octave:${VER}"
  echo "--------------------------------------------------"
  echo "-  Build ${TAG}"
  echo "--------------------------------------------------"
  ${CONTAINER_CMD} build \
    --file      octave-${VER%%.*}.docker \
    --tag       ${TAG} \
    --build-arg OCTAVE_VERSION=${VER} \
    . 2>&1 | tee ${LOG_DIR}/oct-${VER}-$(date +%F_%H-%M-%S).log.txt
  ${CONTAINER_CMD} login docker.io \
    --username ${USERNAME} \
    --password ${PASSWORD}
  ${CONTAINER_CMD} image push ${TAG}
done

