#!/usr/bin/env bash

# Deploy app to local server

export MIX_ENV=prod
APP_NAME=oceanconnect

# Exit on errors
set -e
# set -o errexit -o xtrace

CURDIR="$PWD"
BINDIR=$(dirname "$0")
cd "$BINDIR"; BINDIR="$PWD"; cd "$CURDIR"

BASEDIR="$BINDIR/.."
cd "$BASEDIR"

source "$HOME/.asdf/asdf.sh"

# mix ecto.migrate

mix deploy.local
sudo /bin/systemctl restart "$APP_NAME"

# Save a version file to track what's currently deployed.
git rev-parse --short HEAD > .deployed-version
