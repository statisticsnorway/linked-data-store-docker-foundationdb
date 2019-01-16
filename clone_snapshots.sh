#!/usr/bin/env bash

list_snapshots() {
  perl -0ne 'while(/<dependency>(.*?)<\/dependency>/sg) { print "$1\0" }' | \
  perl -0ne '/<groupId>no\.ssb\..*<\/groupId>/ && /<version>.*-SNAPSHOT<\/version>/ && /.*<artifactId>(.*)<\/artifactId>/ && print "$1\n"'
}

git_clone() {
  while read line; do
    if [ ! -d $line ]; then
      git clone https://github.com/statisticsnorway/${line}.git && cat $line/pom.xml | $0
    fi
  done
}

list_snapshots | git_clone