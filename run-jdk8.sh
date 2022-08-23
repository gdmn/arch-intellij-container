#! /usr/bin/env bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export NAME="idea-jdk8"
ADDITIONAL_ARGUMENTS=""
#if [ -d $XDG_RUNTIME_DIR ]; then
#    ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS -v $XDG_RUNTIME_DIR:/root/tmp"
#fi

BACKGROUND="$(mktemp)"
cat <<EOF >"$BACKGROUND"
    cd /root/code/
    pacman -U --noconfirm *.pkg.tar.zst
    echo 'Background script done'
EOF

ENTRYPOINT="$(mktemp)"
cat <<EOF >"$ENTRYPOINT"
    echo "Arguments: $@"
    archlinux-java set java-8-openjdk
    archlinux-java status
    javac -version
    java -version
    mvn -v
    date
    echo 'Calling background script...'
    bash /root/background.sh &
    cd /root/code/
    idea-ce
EOF

ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS -v $ENTRYPOINT:/root/entrypoint.sh:ro"
ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS -v $BACKGROUND:/root/background.sh:ro"
ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS --entrypoint bash"
export ADDITIONAL_ARGUMENTS
$SCRIPT_DIR/run.sh /root/entrypoint.sh "$@"

