#!/bin/sh

## Helper script to pull all GNU Octave Docker images.

OCTAVE_VERSIONS="\
  jupyterlab \
  6.4.0 \
  6.3.0 \
  6.2.0 \
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


## Pull all Octave images.
for VER in ${OCTAVE_VERSIONS}
do
  ${CONTAINER_CMD} pull "docker.io/gnuoctave/octave:${VER}"
done


## Save disk space and prune unused images.
## Octave builds really require lots of disk space!
${CONTAINER_CMD} image prune --force
