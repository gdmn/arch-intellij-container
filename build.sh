#! /usr/bin/env bash

ADDITIONAL_ARGUMENTS=

if [ -d /var/cache/pacman/pkg ]; then
    echo "Using pacman cache overlay"
    ADDITIONAL_ARGUMENTS="$ADDITIONAL_ARGUMENTS -v /var/cache/pacman/pkg:/var/cache/pacman/pkg:O"
fi

# --no-cache
podman build \
    -t dmn/arch-intellij \
    -f arch-intellij-container/Containerfile \
    $ADDITIONAL_ARGUMENTS
