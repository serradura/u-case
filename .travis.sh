#!/bin/bash

bundle exec rake test

ruby_v=$(ruby -v)

ACTIVEMODEL_VERSION='3.2' bundle update
ACTIVEMODEL_VERSION='3.2' bundle exec rake test

if [[ ! $ruby_v =~ '2.2.0' ]]; then
  ACTIVEMODEL_VERSION='5.2' bundle update
  ACTIVEMODEL_VERSION='5.2' bundle exec rake test
fi
