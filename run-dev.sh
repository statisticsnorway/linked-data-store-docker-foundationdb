#!/usr/bin/env bash

mkdir -p conf
mkdir -p schemas

if [ "$1" == "clean" ]; then
  echo "Cleaning existing associated volumes and data"
  docker-compose down
  docker volume rm $(docker volume ls -q -f "name=ldsfoundationdb")
else
  echo "Reusing existing volumes and data"
fi

ENV_FILE='docker-compose.env'
if [ -f $ENV_FILE ]; then
    export $(grep -v '^#' $ENV_FILE | envsubst | xargs -0)
fi

docker-compose up --remove-orphans
