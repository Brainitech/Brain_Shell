#!/usr/bin/env bash
echo "authenticated"
envycontrol --switch "$1" || exit 1
