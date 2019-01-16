#!/usr/bin/env bash

mvn clean verify dependency:copy-dependencies &&\
docker build -t lds-foundationdb:dev -f Dockerfile-dev .
