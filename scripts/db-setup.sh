#!/usr/bin/env bash

# Set up db

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

echo "Running database setup"

mix ecto.migrate
mix run priv/repo/prod_seeds.exs
