#!/usr/bin/env bash

set -e


# Php minimum version check (minimum version should be lowest version laravel sail support)

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

CURRENT_PHP_VERSION=`php -v | head -n1 | cut -d " " -f 2`
MIN_PHP_VERSION="7.3.0"

if version_gt $MIN_PHP_VERSION $CURRENT_PHP_VERSION; then
    echo "Required php $MIN_PHP_VERSION, install or activate this php version before initialize!"
    exit 1
fi

# Check docker is running or not

if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running, please start docker first!"
  exit 1
fi

# Check sail exists, if not then init
if ! [ -x "$(command -v vendor/bin/sail)" ]; then
  echo "Laravel sail not found, installing sail...."
  COMPOSER=hacks/init/composer.json composer install --no-dev --working-dir=./
  echo "Laravel sail installation done!"
fi

# Create docker network if not exists
if ! docker network inspect smartcomm > /dev/null 2>&1; then
    docker network create --driver bridge smartcomm > /dev/null 2>&1
fi

# Set proper permissions
sudo chmod -R 0777 bootstrap
sudo chmod -R 0777 storage
sudo mkdir -p node_modules
sudo chmod -R 0777 node_modules

# Composer install for sail availability
if [ -f composer.lock ]; then
  rm composer.lock
fi

# check .env exists if not then copy .env.example
if [ ! -f .env ]; then
    cp .env.example .env
fi


# Build
vendor/bin/sail build
vendor/bin/sail up -d
vendor/bin/sail composer install
vendor/bin/sail artisan key:generate
vendor/bin/sail down

echo "Successfully initialized."
echo "To run the application, run the following command:"
echo "./sail up -d"
echo "or"
echo "./sail up"
