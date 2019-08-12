#!/bin/bash

bundle

rm Gemfile.lock

source $(dirname $0)/.travis.sh

rm Gemfile.lock

bundle
