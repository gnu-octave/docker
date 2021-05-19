#!/bin/sh

################
## Configuration
################


# Default image to be used.
OCTAVE_IMAGE="gnuoctave/octave:jupyterlab"


# Default container tool, one of 'docker', 'podman', or 'singularity'.
CONTAINER_TOOL=singularity


################
## Path setup
################

# https://freedesktop.org/wiki/Specifications/menu-spec/
# Version 1.1 20 August 2016

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

BIN_DIR=$HOME/bin
APP_DIR=$XDG_DATA_HOME/applications
ICON_DIR=$XDG_DATA_HOME/icons/hicolor/128x128/apps


function usage()
{
  echo -e "\nUsage: $0 [-t container-tool] [-d]\n"
  echo -e "\t-d --debug           verbose debug output"
  echo -e "\t-f --force           overwrite previous installations"
  echo -e "\t-h --help            show this help"
  echo -e "\t-t --container-tool  one of 'docker', 'podman', or 'singularity'"
  echo -e "\t-u --uninstall       only uninstall previous setups\n"
  exit 1
}


# Loop through command-line arguments and process them.
DEBUG=false
FORCE=false
UNINSTALL_ONLY=false
while [ "$1" != "" ]
do
  case $1 in
    -d|--debug)
      DEBUG=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -t|--container-tool)
      CONTAINER_TOOL="$2"
      shift
      shift
      ;;
    -u|--uninstall)
      UNINSTALL_ONLY=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "\nError: invalid input '$1'."
      usage
      ;;
  esac
done


# Common variables for container tools.
CONTAINER_PULL_CMD="pull docker.io/$OCTAVE_IMAGE"
CONTAINER_RUN_CMD="run \
  --rm \
  --network=host \
  --env=\"DISPLAY\" \
  --volume=\"\$HOME/:\$HOME:rw\" \
  $OCTAVE_IMAGE"


# Setup for the container tool.
case $CONTAINER_TOOL in
  "docker")
    CMD=docker
    PULL_CMD=$CONTAINER_PULL_CMD
    RUN_CMD=$CONTAINER_RUN_CMD
    ;;
  "podman")
    CMD=podman
    PULL_CMD=$CONTAINER_PULL_CMD
    RUN_CMD=$CONTAINER_RUN_CMD
    ;;
  "singularity")
    CMD=singularity
    SIF_FILE="$BIN_DIR/octave_jupyterlab.sif"
    PULL_CMD="pull --disable-cache $SIF_FILE docker://$OCTAVE_IMAGE"
    RUN_CMD="exec --bind /run/user $SIF_FILE"
    ;;
  *)
    echo -e "\nError: invalid container tool '$CONTAINER_TOOL'."
    usage
esac


# Check if container tool is ready to use.
if ! type $CMD &> /dev/null
then
  echo -e "\nError: $CMD could not be found, please choose another container tool:"
  echo -e "\n       install.sh -t container-tool\n"
  exit 1
fi

if $DEBUG
then
  echo "DEBUG: use '$CMD' as container tool."
fi


# Check for previous or colliding installations.
PREV_INSTALL=""

#FIXME: add again $SIF_FILE
INSTALLED_FILES=" \
  $BIN_DIR/mkoctfile
  $BIN_DIR/octave
  $BIN_DIR/octave-config
  $BIN_DIR/octave-cli
  $BIN_DIR/octave-jupyterlab
  $APP_DIR/octave-docker.desktop
  $APP_DIR/octave-docker-jupyterlab.desktop
  $ICON_DIR/jupyter-logo-128.png
  $ICON_DIR/octave-logo-128.png"
for f in $INSTALLED_FILES
do
  if [ -f "$f" ]
  then
    PREV_INSTALL+=" $f "
  fi
done

if [ -n "$PREV_INSTALL" ]
then
  # Report previous installation.
  echo -e "\nFound previous installation:\n"
  for f in $PREV_INSTALL
  do
    echo "  $f"
  done
  echo " "

  # Ask user for confirmation (regard -f --force).
  if ! $FORCE
  then
    while true; do
      read -p "Enter [c] to cancel and [d] to delete previous installations. " yn
      case $yn in
          [Cc]*)
            echo -e "\nInstallation canceled.\n"
            exit 1
            ;;
          [Dd]*)
            break
            ;;
          *)
            echo "Please answer [c] or [d]."
            ;;
      esac
    done
  fi

  for f in $PREV_INSTALL
  do
    rm -f "$f"
  done
fi


# Finish here if only uninstall was requested.

if $UNINSTALL_ONLY
then
  echo -e "\nUninstall finished.\n"
  if [ "$CMD" != "singularity" ]
  then
    echo -e "  Please remove any '$CMD' images manually.\n"
  fi
  exit 0
fi


# Get images

$CMD $PULL_CMD


# Install binary files.

echo "#!/bin/sh
$CMD $RUN_CMD \"\${0##*/}\" \"\$@\"" > $BIN_DIR/octave
chmod +x $BIN_DIR/octave
ln -sf $BIN_DIR/octave $BIN_DIR/mkoctfile
ln -sf $BIN_DIR/octave $BIN_DIR/octave-config
ln -sf $BIN_DIR/octave $BIN_DIR/octave-cli


#TODO
echo "#!/bin/sh" > $BIN_DIR/octave-jupyterlab
chmod +x $BIN_DIR/octave-jupyterlab


# Install desktop file icons.

ICON_URL="https://raw.githubusercontent.com/gnu-octave/docker/main/assets"
WGET_FLAGS="--directory-prefix=$ICON_DIR"
if ! $DEBUG
then
  WGET_FLAGS+=" --quiet"
fi
if [ ! -f "$ICON_DIR/jupyter-logo-128.png" ]
then
  wget $WGET_FLAGS $ICON_URL/jupyter-logo-128.png
fi
if [ ! -f "$ICON_DIR/octave-logo-128.png" ]
then
  wget $WGET_FLAGS $ICON_URL/octave-logo-128.png
fi


# Install desktop files.

function get_JupyterLab_desktop_file()
{
  echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Categories=Education;Science;Math;
Comment=Web-based JupyterLab user interface for Octave
Exec=$BIN_DIR/octave-jupyterlab
GenericName=JupyterLab Octave
Icon=$ICON_DIR/jupyter-logo-128.png
MimeType=
Name=JupyterLab Octave
StartupNotify=true
Terminal=false
Type=Application
StartupWMClass=JupyterLab Octave"
}

function get_Octave_desktop_file()
{
  echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Categories=Education;Science;Math;
Comment=Interactive programming environment for numerical computations
Comment[ca]=Entorn de programació interactiva per a càlculs numèrics
Comment[de]=Interaktive Programmierumgebung für numerische Berechnungen
Comment[es]=Entorno de programación interactiva para cálculos numéricos
Comment[fr]=Environnement de programmation interactif pour le calcul numérique
Comment[it]=Ambiente di programmazione interattivo per il calcolo numerico
Comment[ja]=数値計算のための対話的なプログラミング環境
Comment[nl]=Interactieve programmeeromgeving voor numerieke berekeningen
Comment[pt]=Ambiente de programação interativo para computação numérica
Comment[zh]=数值计算交互式编程环境
Exec=$BIN_DIR/octave --gui -q %f
GenericName=GNU Octave
Icon=$ICON_DIR/octave-logo-128.png
MimeType=text/x-octave;text/x-matlab;
Name=GNU Octave
StartupNotify=true
Terminal=false
Type=Application
StartupWMClass=GNU Octave
Keywords=science;math;matrix;numerical computation;plotting;"
}

WORK_DIR=$(mktemp -d)

get_Octave_desktop_file     > $WORK_DIR/octave-docker.desktop
get_JupyterLab_desktop_file > $WORK_DIR/octave-docker-jupyterlab.desktop

if $DEBUG
then
  desktop-file-validate $WORK_DIR/octave-docker.desktop
  desktop-file-validate $WORK_DIR/octave-docker-jupyterlab.desktop
fi

for f in "octave-docker.desktop" "octave-docker-jupyterlab.desktop"
do
  desktop-file-install        \
    --dir=$APP_DIR            \
    --delete-original         \
    --rebuild-mime-info-cache \
    $WORK_DIR/$f
done

echo -e "\nInstallation was successful."
echo -e "\n  Run Octave with:\n\n\t$BIN_DIR/octave --gui"
echo -e "\n  Run JupyterLab Octave with:\n\n\t$BIN_DIR/octave-jupyterlab"
echo -e "\n  Desktop launcher have been created as well.\n\n"
