#!/bin/sh

################
## Configuration
################

# Default Octave Docker image to be used.
OCTAVE_VERSION="7.3.0"
OCTAVE_IMAGE="docker.io/gnuoctave/octave"

# Choose default container tool in this order.
CONTAINER_TOOL_HIERARCHY="docker, podman, singularity"

#############
## Path setup
#############

# https://freedesktop.org/wiki/Specifications/menu-spec/
# Version 1.1 20 August 2016

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

BIN_DIR=$HOME/bin
APP_DIR=$XDG_DATA_HOME/applications
ICON_DIR=$XDG_DATA_HOME/icons/hicolor/128x128/apps

# Ensure directories to exist.
mkdir -p $BIN_DIR
mkdir -p $APP_DIR
mkdir -p $ICON_DIR

function usage()
{
  if [ -n "$1" ]
  then
    echo -e "\nError: $1"
  fi
  echo -e "\nUsage: $0 with options:\n"
  echo -e "\t-d --debug           verbose debug output"
  echo -e "\t-f --force           overwrite previous installations"
  echo -e "\t-h --help            show this help"
  echo -e "\t-t --container-tool  one of $CONTAINER_TOOL_HIERARCHY"
  echo -e "\t-u --uninstall       only uninstall previous setups\n"
  exit 1
}


###################################
## Command-line argument processing
###################################

DEBUG=false
FORCE=false
QUIET_FLAG="--quiet"
UNINSTALL_ONLY=false
while [ "$1" != "" ]
do
  case $1 in
    -d|--debug)
      DEBUG=true
      QUIET_FLAG=""
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
      usage "invalid input '$1'."
      ;;
  esac
done


# Debug output function.
function DEBUG_MSG()
{
  if $DEBUG
  then
    echo -e "\nDEBUG: $1\n"
  fi
}


#####################################
## Container tool detection and setup
#####################################

if [ -z $CONTAINER_TOOL ]
then
  for t in $(echo $CONTAINER_TOOL_HIERARCHY | tr "," "\n")
  do
    # Use first existing tool
    if type "$t" &> /dev/null
    then
      CONTAINER_TOOL=$t
      break
    fi
  done
  if [ -z $CONTAINER_TOOL ]
  then
    usage "No container tool ($CONTAINER_TOOL_HIERARCHY) could be detected." \
          "Please install one of them."
  fi
else
  if ! type "$CONTAINER_TOOL" &> /dev/null
  then
    echo -e "\nError: '$CONTAINER_TOOL' cannot be found,"\
                      "please choose another container tool."
    usage
  fi
fi
DEBUG_MSG "use '$CONTAINER_TOOL' as container tool."

# Setup for the container tool.
case $CONTAINER_TOOL in
  "docker" | "podman")
    PULL_CMD="$CONTAINER_TOOL pull $QUIET_FLAG $OCTAVE_IMAGE:$OCTAVE_VERSION"
    RUN_CMD="$CONTAINER_TOOL run \$DOCKER_INTERACTIVE \\
           --rm \\
           --network=host \\
           --env=\"DISPLAY\" \\
           --env=\"XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR\" \\
           --user \$(id -u):\$(id -g) \\
           --volume=\"\$HOME:\$HOME:rw\" \\
           --volume=\"\$OCTAVE_CONF_DIR_HOST:\$OCTAVE_CONF_DIR:rw\" \\
           --volume=\"/dev:/dev:rw\" \\
           --volume=\"/run/user:/run/user:rw\" \\
           $OCTAVE_IMAGE:\$OCTAVE_VERSION"
    ;;
  "singularity")
    SIF_FILE="$BIN_DIR/octave_${OCTAVE_VERSION}.sif"
    PULL_CMD="$CONTAINER_TOOL pull --disable-cache $SIF_FILE \
              ${OCTAVE_IMAGE/docker.io/docker:/}:${OCTAVE_VERSION}"
    R_CMD="--bind /run/user,\$OCTAVE_CONF_DIR_HOST:\$OCTAVE_CONF_DIR $SIF_FILE"
    RUN_CMD="$CONTAINER_TOOL exec $R_CMD"
    ;;
  *)
    echo -e "\nError: invalid container tool '$CONTAINER_TOOL'."
    usage
esac


################################
## Detect previous installations
################################

PREV_INSTALL=""

INSTALLED_FILES=" \
  $BIN_DIR/mkoctfile
  $BIN_DIR/octave
  $BIN_DIR/octave-config
  $BIN_DIR/octave-cli
  $APP_DIR/octave-docker.desktop
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
  if [ "$CONTAINER_TOOL" = "singularity" ]
  then
    if [ -f $SIF_FILE ]
    then
      echo -e "  Please remove the singularity SIF-file manually.\n"
      echo -e "  rm -f $SIF_FILE\n"
    fi
  else
    echo -e "  Please remove any '$CONTAINER_TOOL' images manually.\n"
    echo -e "  $CONTAINER_TOOL rmi ${OCTAVE_IMAGE/docker.io\//}\n"
  fi
  exit 0
fi


###################
## New installation
###################

# Get images

echo -e "\nPull '$OCTAVE_IMAGE:$OCTAVE_VERSON' image with '$CONTAINER_TOOL'...\n"
bash -c "$PULL_CMD"


# Install start scripts.

function get_Octave_start_script()
{
  echo "#!/bin/bash

OCTAVE_VERSION=\"\${OCTAVE_VERSION:-\"$OCTAVE_VERSION\"}\"

DOCKER_INTERACTIVE=\"-it\"
for arg in \"\$@\"
do
  if [[ \"\$arg\" == \"--gui\" ]]
  then
    DOCKER_INTERACTIVE=\"\"
  fi
  # Old Octave qt4 builds
  if [[ \"\$arg\" == \"--force-gui\" ]]
  then
    DOCKER_INTERACTIVE=\"--env=QT_GRAPHICSSYSTEM=native\"
  fi
done

## Avoid collisions with different 'OCTAVE_VERSION's
XDG_CONFIG_HOME=\"\${XDG_CONFIG_HOME:-\$HOME/.config}\"
OCTAVE_CONF_DIR=\"\$XDG_CONFIG_HOME/octave\"
OCTAVE_CONF_DIR_HOST=\"\$OCTAVE_CONF_DIR/\$OCTAVE_VERSION\"
mkdir -p \"\$OCTAVE_CONF_DIR_HOST\"

$RUN_CMD \"\${0##*/}\" \"\$@\"
"
}


get_Octave_start_script > $BIN_DIR/octave
chmod u+x $BIN_DIR/octave
ln -sf $BIN_DIR/octave $BIN_DIR/mkoctfile
ln -sf $BIN_DIR/octave $BIN_DIR/octave-config
ln -sf $BIN_DIR/octave $BIN_DIR/octave-cli


# Install desktop file icon.

ICON_URL="https://raw.githubusercontent.com/gnu-octave/docker/main/assets"
WGET_FLAGS="--directory-prefix=$ICON_DIR $QUIET_FLAG"
if [ ! -f "$ICON_DIR/octave-logo-128.png" ]
then
  wget $WGET_FLAGS $ICON_URL/octave-logo-128.png
fi


# Install desktop file.

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


TMP_DESKTOP_FILE="$(mktemp -d)/octave-docker.desktop"

get_Octave_desktop_file > ${TMP_DESKTOP_FILE}

if $DEBUG
then
    desktop-file-validate ${TMP_DESKTOP_FILE}
fi

desktop-file-install          \
    --dir=$APP_DIR            \
    --delete-original         \
    --rebuild-mime-info-cache \
    ${TMP_DESKTOP_FILE}

echo -e "\nInstallation was successful."
echo -e "\n  Run Octave with:\n\n\t$BIN_DIR/octave --gui"
echo -e "\n  Desktop launcher has been created.\n\n"
