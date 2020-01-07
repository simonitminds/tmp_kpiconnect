#!/usr/bin/env bash

# Build production release

export MIX_ENV=prod

# Exit on errors
set -e
# set -o errexit -o xtrace

CURDIR="$PWD"
BINDIR=$(dirname "$0")
cd "$BINDIR"; BINDIR="$PWD"; cd "$CURDIR"

BASEDIR="$BINDIR/.."
cd "$BASEDIR"

source "$HOME/.asdf/asdf.sh"

echo "Pulling latest code from git"
git pull

echo "Updating versions of Erlang/Elixir/Node.js if necessary"
asdf install
# ASDF is currently changing the way it handles return codes
# Until that's all sorted, we need to run it twice.
asdf install

echo "Updating Elixir libs"
mix local.hex --if-missing --force
mix local.rebar --if-missing --force
mix deps.get --only "$MIX_ENV"

echo "Compiling"
mix compile

echo "Updating node libraries"
# Export path for node, yarn, and yarn dependencies to allow for remote usage
export PATH=/home/deploy/.asdf/shims:/home/deploy/.yarn/bin:/bin:/usr/bin
(cd assets && yarn build)

echo "Building release"
mix do phx.digest, release
