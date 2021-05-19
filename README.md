# Docker images of GNU Octave

> https://hub.docker.com/r/gnuoctave/octave

The Octave images can be run by
- [Docker](https://www.docker.com/):
  ```sh
  # Obtain image
  docker pull docker.io/gnuoctave/octave:6.2.0
  # Start container (command-line interface)
  docker run -it --rm gnuoctave/octave:6.2.0 octave
  # Start container GUI (experimental)
  docker run \
    --rm \
    --network=host \
    --env="DISPLAY" \
    --volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
    gnuoctave/octave:6.2.0 \
    octave --gui
  ```
- [Podman](https://podman.io/): as before, replace `docker` with `podman`.
- [Singularity](https://sylabs.io/singularity/): most recommended for GUI mode.
  ```sh
  singularity pull docker://gnuoctave/octave:6.2.0
  # Start container (command-line interface)
  singularity run octave_6.2.0.sif
  # Start container GUI (experimental)
  singularity exec --bind /run/user octave_6.2.0.sif octave --gui
  ```

## Hierarchy of all available images

![Image hierarchy.](doc/docker_image_hierachy.png)
