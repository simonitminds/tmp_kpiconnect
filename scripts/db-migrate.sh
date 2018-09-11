#!/usr/bin/env bash

# Run db migrations

export MIX_ENV=prod
export PORT=4004

# Exit on errors
set -e
# set -o errexit -o xtrace

CURDIR="$PWD"
BINDIR=$(dirname "$0")
cd "$BINDIR"; BINDIR="$PWD"; cd "$CURDIR"

BASEDIR="$BINDIR/.."
cd "$BASEDIR"

source "$HOME/.asdf/asdf.sh"

echo "Running database migrationse"

mix ecto.migrate
