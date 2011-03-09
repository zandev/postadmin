#!/bin/bash

compact() {
  IFS=$'\n'
  for line in $(cat src/postadmin); do
    token="# sourcing libpostadmin.sh"
    if [[ "$line" =~ source ]] && [[ "$lastline" =~ $token ]]; then
      cat src/libpostadmin.sh
    else
      echo "$line"
      lastline="$line"
    fi
  done
}

[ -d build ] && rm -rf build

mkdir build
compact > build/postadmin
chmod u+x build/postadmin
cp -p src/postadmin.conf.sample build/postadmin.conf
