# Docker images of GNU Octave

> - DockerHub: https://hub.docker.com/r/gnuoctave/octave
> - GitHub: https://github.com/gnu-octave/docker

The Octave images can be run by
- [Docker](https://www.docker.com/):
  ```sh
  # Obtain image

  docker pull docker.io/gnuoctave/octave:10.2.0

  # Start container (command-line interface)

  docker run -it --rm gnuoctave/octave:10.2.0 octave
  ```
- [Podman](https://podman.io/): as before, replace `docker` with `podman`.
- [Singularity](https://sylabs.io/singularity/):
  ```sh
  singularity pull docker://gnuoctave/octave:10.2.0

  # Start container (command-line interface)

  singularity run octave_10.2.0.sif
  ```

See below for starting Octave with GUI and advanced options, like mounting the host's user directory.


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
  docker.io/gnuoctave/octave:10.2.0 octave --gui
```

For old Octave 4.x.x versions you might additionally pass the
`--env=QT_GRAPHICSSYSTEM=native` environment variable.

The following error results from a missing `$HOME/.Xauthority` file:
```
Authorization required, but no authorization protocol specified
octave: unable to open X11 DISPLAY
octave: disabling GUI features
```
Create this file via `ln -s -f "$XAUTHORITY" $HOME/.Xauthority`.

> **Note:** The best experience was made with Singularity and Docker.
> Podman had several flaws when run as unprivileged (non-root) user.

> **Note:** The "Easy installation" described above does a few tweaks
> to the `docker run` command to enable parallel usage of multiple Octave
> versions and `sudo`-support for the non-root user.


Using Singularity, start Octave with GUI with this command:
```
singularity exec --bind /run/user octave_10.2.0.sif octave --gui
```


## Use qt graphics_toolkit in headless environments

If the container image is not started or able to start as explained in the previous section,
using the hosts graphics environment, only "gnuplot" is available:
```
docker run --rm -it gnuoctave/octave:9.4.0 bash

root@03cb8555f83f:/workdir# octave --eval available_graphics_toolkits
octave: X11 DISPLAY environment variable not set
octave: disabling GUI features
ans =
{
  [1,1] = gnuplot
}
```

To make advanced "qt" graphics available in headless environments,
one potential solution is install the following packages at container image startup
and start Octave using `xvfb-run`:
```
$ xvfb-run octave --eval available_graphics_toolkits
QStandardPaths: XDG_RUNTIME_DIR not set, defaulting to '/tmp/runtime-root'
ans =
{
  [1,1] = fltk
  [1,2] = gnuplot
  [1,3] = qt
}
```

For details, see [Xvfb](https://en.wikipedia.org/wiki/Xvfb)
and [#27](https://github.com/gnu-octave/docker/issues/27#issuecomment-2703629974)
with thanks to [@ELC](https://github.com/ELC).


## Hierarchy of all available images

```mermaid
graph LR
    U5[ubuntu:<b>2404</b>] --> b9[docker.io/gnuoctave/octave-build:<b>9</b>];
    U4[ubuntu:<b>2204</b>] --> b8[docker.io/gnuoctave/octave-build:<b>8</b>];
    U3[ubuntu:<b>2004</b>] --> b6[docker.io/gnuoctave/octave-build:<b>6</b>];
    U2[ubuntu:<b>1804</b>] --> b5[docker.io/gnuoctave/octave-build:<b>5</b>];
    U1[ubuntu:<b>1604</b>] --> b4[docker.io/gnuoctave/octave-build:<b>4</b>];
    b9 --> v1020[docker.io/gnuoctave/octave:<b>10.2.0</b>];
    b9 --> v1010[docker.io/gnuoctave/octave:<b>10.1.0</b>];
    b9 --> v940[docker.io/gnuoctave/octave:<b>9.4.0</b>];
    b9 --> v930[docker.io/gnuoctave/octave:<b>9.3.0</b>];
    b9 --> v920[docker.io/gnuoctave/octave:<b>9.2.0</b>];
    b9 --> v910[docker.io/gnuoctave/octave:<b>9.1.0</b>];
    b8 --> v840[docker.io/gnuoctave/octave:<b>8.4.0</b>];
    b8 --> v830[docker.io/gnuoctave/octave:<b>8.3.0</b>];
    b8 --> v820[docker.io/gnuoctave/octave:<b>8.2.0</b>];
    b8 --> v810[docker.io/gnuoctave/octave:<b>8.1.0</b>];
    b6 --> v730[docker.io/gnuoctave/octave:<b>7.3.0</b>];
    b6 --> v720[docker.io/gnuoctave/octave:<b>7.2.0</b>];
    b6 --> v710[docker.io/gnuoctave/octave:<b>7.1.0</b>];
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
    class U5 U;
    classDef b fill:#ff0,stroke:#333,stroke-width:2px;
    class b4 b;
    class b5 b;
    class b6 b;
    class b8 b;
    class b9 b;
    classDef age1 fill:#9aff9a,stroke:#333,stroke-width:2px;
    classDef age2 fill:#7fffd4,stroke:#333,stroke-width:2px;
    classDef age3 fill:#fff68f,stroke:#333,stroke-width:2px;
    classDef age4 fill:#ffd700,stroke:#333,stroke-width:2px;
    classDef age5 fill:#ffa500,stroke:#333,stroke-width:2px;
    classDef age6 fill:#ff6a6a,stroke:#333,stroke-width:2px;
    class v1020 age1;
    class v1010 age1;
    class v940 age1;
    class v930 age1;
    class v920 age1;
    class v910 age1;
    class v840 age1;
    class v830 age1;
    class v820 age1;
    class v810 age1;
    class v730 age2;
    class v720 age2;
    class v710 age2;
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
