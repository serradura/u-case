#!/bin/bash

git checkout -- Gemfile.lock

source $(dirname $0)/.travis.sh

git checkout -- Gemfile.lock
