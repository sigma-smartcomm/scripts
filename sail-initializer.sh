#!/usr/bin/env bash

set -e

# Php minimum version check (minimum version should be lowest version laravel sail support)

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

CURRENT_PHP_VERSION=`php -v | head -n1 | cut -d " " -f 2`
MIN_PHP_VERSION=${MIN_PHP_VERSION:-"7.3.0"}

if version_gt $MIN_PHP_VERSION $CURRENT_PHP_VERSION; then
    echo "Required php $MIN_PHP_VERSION, install or activate this php version before initialize!"
    exit 1
fi

# Check docker is running or not
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running, please start docker first!"
  exit 1
fi

DOCKER_NETWORK_NAME=${DOCKER_NETWORK_NAME:-smartcomm}
# Create docker network if not exists
if ! docker network inspect $DOCKER_NETWORK_NAME > /dev/null 2>&1; then
    docker network create --driver bridge $$DOCKER_NETWORK_NAME > /dev/null 2>&1
fi


# Check if project is valid composer project and support sail

if [ ! -f composer.json ]; then
    echo "Project is not valid composer project."
    exit 1
fi

# Check sail exists, if not then init

if ! [ -x "$(command -v vendor/bin/sail)" ]; then
  echo "Laravel sail not found, installing sail...."
  curl https://raw.githubusercontent.com/sigma-smartcomm/scripts/main/composer.json > /tmp/composer-sail-1.json
  COMPOSER=/tmp/composer-sail-1.json composer install --no-dev --working-dir=./
  echo "Laravel sail installation done!"
  rm -f /tmp/sail-1.json
fi

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
vendor/bin/sail composer install --no-scripts

vendor/bin/sail artisan key:generate
vendor/bin/sail down

echo "Successfully initialized."
echo "To run the application, run the following command:"
echo "./sail up -d"
echo "or"
echo "./sail up"
