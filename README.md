# Docker images of GNU Octave

> - DockerHub: https://hub.docker.com/r/gnuoctave/octave
> - GitHub: https://github.com/gnu-octave/docker

The Octave images can be run by
- [Docker](https://www.docker.com/):
  ```sh
  # Obtain image

  docker pull docker.io/gnuoctave/octave:8.4.0

  # Start container (command-line interface)

  docker run -it --rm gnuoctave/octave:8.4.0 octave
  ```
- [Podman](https://podman.io/): as before, replace `docker` with `podman`.
- [Singularity](https://sylabs.io/singularity/): most recommended for GUI mode.
  ```sh
  singularity pull docker://gnuoctave/octave:8.4.0

  # Start container (command-line interface)

  singularity run octave_8.4.0.sif
  ```

See below for starting Octave with GUI.


## Easy installation

An installation script is provided,
that can be called directly with this shell command:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/gnu-octave/docker/main/install.sh)" -t docker
```
To remove the installation, type:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/gnu-octave/docker/main/install.sh)" -u -f
```
It creates links in `$HOME/bin`,
as well as a Desktop entry,
to start the Octave as if it was installed by the Linux distribution.

**Note:** The system must have either Docker (= Podman) or Singularity
installed and the user account must be setup to use those tools properly.
Please adapt the shell command after `-t` respectively.


## Starting the Octave GUI

Using Singularity, start Octave with GUI with this command:
```
singularity exec --bind /run/user octave_8.4.0.sif octave --gui
```

Using Docker or Podman run:
```sh
docker run \
  --rm \
  --network=host \
  --env="DISPLAY" \
  --env="HOME=$HOME" \
  --env="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
  --user $(id -u):$(id -g) \
  --volume="$HOME:$HOME:rw" \
  --volume="/dev:/dev:rw" \
  --volume="/run/user:/run/user:rw" \
  --workdir="$HOME" \
  docker.io/gnuoctave/octave:8.4.0 octave --gui
```

For old Octave 4.x.x versions you might additionally pass the
`--env=QT_GRAPHICSSYSTEM=native` environment variable.

> **Note:** The best experience was made with Singularity and Docker.
> Podman had several flaws when run as unprivileged (non-root) user.

> **Note:** The "Easy installation" described above does a few tweaks
> to the `docker run` command to enable parallel usage of multiple Octave
> versions and `sudo`-support for the non-root user.

## Hierarchy of all available images

```mermaid
graph LR
    U4[ubuntu:<b>2204</b>] --> b7[docker.io/gnuoctave/octave-build:<b>7</b>];
    U3[ubuntu:<b>2004</b>] --> b6[docker.io/gnuoctave/octave-build:<b>6</b>];
    U2[ubuntu:<b>1804</b>] --> b5[docker.io/gnuoctave/octave-build:<b>5</b>];
    U1[ubuntu:<b>1604</b>] --> b4[docker.io/gnuoctave/octave-build:<b>4</b>];
    b7 --> v840[docker.io/gnuoctave/octave:<b>8.4.0</b>];
    b7 --> v830[docker.io/gnuoctave/octave:<b>8.3.0</b>];
    b7 --> v820[docker.io/gnuoctave/octave:<b>8.2.0</b>];
    b7 --> v810[docker.io/gnuoctave/octave:<b>8.1.0</b>];
    b7 --> v730[docker.io/gnuoctave/octave:<b>7.3.0</b>];
    b7 --> v720[docker.io/gnuoctave/octave:<b>7.2.0</b>];
    b7 --> v710[docker.io/gnuoctave/octave:<b>7.1.0</b>];
    b6 --> v640[docker.io/gnuoctave/octave:<b>6.4.0</b>];
    b6 --> v630[docker.io/gnuoctave/octave:<b>6.3.0</b>];
    b6 --> v620[docker.io/gnuoctave/octave:<b>6.2.0</b>];
    b6 --> v610[docker.io/gnuoctave/octave:<b>6.1.0</b>];
    b5 --> v520[docker.io/gnuoctave/octave:<b>5.2.0</b>];
    b5 --> v510[docker.io/gnuoctave/octave:<b>5.1.0</b>];
    b5 --> v441[docker.io/gnuoctave/octave:<b>4.4.1</b>];
    b5 --> v440[docker.io/gnuoctave/octave:<b>4.4.0</b>];
    b4 --> v422[docker.io/gnuoctave/octave:<b>4.2.2</b>];
    b4 --> v421[docker.io/gnuoctave/octave:<b>4.2.1</b>];
    b4 --> v420[docker.io/gnuoctave/octave:<b>4.2.0</b>];
    b4 --> v403[docker.io/gnuoctave/octave:<b>4.0.3</b>];
    b4 --> v402[docker.io/gnuoctave/octave:<b>4.0.2</b>];
    b4 --> v401[docker.io/gnuoctave/octave:<b>4.0.1</b>];
    b4 --> v400[docker.io/gnuoctave/octave:<b>4.0.0</b>];
    classDef U fill:#ff7f24,stroke:#333,stroke-width:2px;
    class U1 U;
    class U2 U;
    class U3 U;
    class U4 U;
    classDef b fill:#ff0,stroke:#333,stroke-width:2px;
    class b4 b;
    class b5 b;
    class b6 b;
    class b7 b;
    classDef age1 fill:#9aff9a,stroke:#333,stroke-width:2px;
    classDef age2 fill:#7fffd4,stroke:#333,stroke-width:2px;
    classDef age3 fill:#fff68f,stroke:#333,stroke-width:2px;
    classDef age4 fill:#ffd700,stroke:#333,stroke-width:2px;
    classDef age5 fill:#ffa500,stroke:#333,stroke-width:2px;
    classDef age6 fill:#ff6a6a,stroke:#333,stroke-width:2px;
    class v840 age1;
    class v830 age1;
    class v820 age1;
    class v810 age1;
    class v730 age1;
    class v720 age1;
    class v710 age1;
    class v640 age2;
    class v630 age2;
    class v620 age2;
    class v610 age2;
    class v520 age3;
    class v510 age3;
    class v441 age4;
    class v440 age4;
    class v422 age5;
    class v421 age5;
    class v420 age5;
    class v403 age6;
    class v402 age6;
    class v401 age6;
    class v400 age6;
```


## Further reading

- <https://siko1056.github.io/blog/2021/06/10/octave-docker.html>
  A longer blog article about this project including descriptions how to use
  and customize these images for specific needs.
