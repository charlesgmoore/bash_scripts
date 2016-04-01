#!/bin/bash

file='/etc/hosts'
date=$(date "+%Y-%m-%d %H:%M:%S")

if [ -z $1 ]; then
  echo "You did not specify an IP address"
  exit 1
elif [ -z $2 ]; then
  echo "You did not specify a domain"
  exit 1
fi

echo -e "$1\t$2 www.$2\t\t\t##$date" >> $file

