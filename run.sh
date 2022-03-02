#! /usr/bin/env bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if ! podman image exists dmn/arch-intellij; then
    echo 'Building image'
    $SCRIPT_DIR/build.sh
fi
if ! podman image exists dmn/arch-intellij; then
    echo 'Image not found'
    exit 1
fi

ADDITIONAL_ARGUMENTS="${ADDITIONAL_ARGUMENTS:-}"
CONF_SCRIPT="${CONF_SCRIPT:-}"
NAME="${NAME:-idea-default}"

if [ "$1" == "-d" ]; then
    shift
    PROFILE="$1"
    CONF_SCRIPT="$PROFILE/idea.conf"
    shift
fi
if [ "$1" == "-c" ]; then
    # see my-idea-example.conf
    shift
    CONF_SCRIPT="$1"
    shift
fi

if  [ -z "$CONF_SCRIPT" ]; then
    echo "Profile configuration not given"
elif [ -r "$CONF_SCRIPT" ]; then
    echo "Sourcing $CONF_SCRIPT..."
    source "$CONF_SCRIPT" || exit 1
else
    echo "Could not source $CONF_SCRIPT"
fi

PROFILE="${PROFILE:-$HOME/idea/$NAME}"
mkdir -p "$PROFILE"
echo "The profile files are in $PROFILE"

if [ -d /var/cache/pacman/pkg ]; then
    echo "Using pacman cache overlay"
    ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS -v /var/cache/pacman/pkg:/var/cache/pacman/pkg:O"
fi

mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ -d ~/.ssh ]; then
    ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS -v $HOME/.ssh:/root/.ssh"
fi

touch ~/.gitconfig
if [ -r ~/.gitconfig ]; then
    ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS -v $HOME/.gitconfig:/root/.gitconfig"
fi

IDEA_DIR_PROFILE_DOT_LOCAL_SHARE="${IDEA_DIR_PROFILE_DOT_LOCAL_SHARE:-$PROFILE/.local/share/JetBrains}"
IDEA_DIR_PROFILE_DOT_CONFIG="${IDEA_DIR_PROFILE_DOT_CONFIG:-$PROFILE/.config/JetBrains}"
IDEA_DIR_PROFILE_DOT_CACHE="${IDEA_DIR_PROFILE_DOT_CACHE:-$PROFILE/.cache/JetBrains}"
IDEA_DIR_PROFILE_DOT_M2="${IDEA_DIR_PROFILE_DOT_M2:-$PROFILE/.m2}"
IDEA_DIR_PROFILE_DOT_JAVA="${IDEA_DIR_PROFILE_DOT_JAVA:-$PROFILE/.java}"
IDEA_DIR_PROFILE_PROJECTS="${IDEA_DIR_PROFILE_PROJECTS:-$PROFILE/code}"

cat <<EOF
IDEA_DIR_PROFILE_DOT_LOCAL_SHARE=   $IDEA_DIR_PROFILE_DOT_LOCAL_SHARE
IDEA_DIR_PROFILE_DOT_CONFIG=        $IDEA_DIR_PROFILE_DOT_CONFIG
IDEA_DIR_PROFILE_DOT_CACHE=         $IDEA_DIR_PROFILE_DOT_CACHE
IDEA_DIR_PROFILE_DOT_M2=            $IDEA_DIR_PROFILE_DOT_M2
IDEA_DIR_PROFILE_DOT_JAVA=          $IDEA_DIR_PROFILE_DOT_JAVA
IDEA_DIR_PROFILE_PROJECTS=          $IDEA_DIR_PROFILE_PROJECTS
ADDITIONAL_ARGUMENTS=               $ADDITIONAL_ARGUMENTS
EOF

mkdir -p "$IDEA_DIR_PROFILE_DOT_LOCAL_SHARE" \
  "$IDEA_DIR_PROFILE_DOT_CONFIG" \
  "$IDEA_DIR_PROFILE_DOT_CACHE" \
  "$IDEA_DIR_PROFILE_DOT_M2" \
  "$IDEA_DIR_PROFILE_DOT_JAVA" \
  "$IDEA_DIR_PROFILE_PROJECTS"

echo ""
echo "Executing podman $NAME..."
podman run --net=host --rm -e DISPLAY -v $XAUTHORITY:/root/.Xauthority \
    -it \
    -v "$IDEA_DIR_PROFILE_DOT_LOCAL_SHARE:/root/.local/share/JetBrains" \
    -v "$IDEA_DIR_PROFILE_DOT_CONFIG:/root/.config/JetBrains" \
    -v "$IDEA_DIR_PROFILE_DOT_CACHE:/root/.cache/JetBrains" \
    -v "$IDEA_DIR_PROFILE_DOT_M2:/root/.m2" \
    -v "$IDEA_DIR_PROFILE_DOT_JAVA:/root/.java" \
    -v "$IDEA_DIR_PROFILE_PROJECTS:/root/code" \
    $ADDITIONAL_ARGUMENTS \
    --name $NAME dmn/arch-intellij "$@"

