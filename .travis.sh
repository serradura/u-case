#!/bin/bash

ruby_v=$(ruby -v)

ACTIVEMODEL_VERSION='3.2' bundle update
ACTIVEMODEL_VERSION='3.2' ENABLE_TRANSITIONS='true' bundle exec rake test
ACTIVEMODEL_VERSION='3.2' ENABLE_TRANSITIONS='false' bundle exec rake test

if [[ ! $ruby_v =~ '2.2.0' ]]; then
  ACTIVEMODEL_VERSION='5.2' bundle update
  ACTIVEMODEL_VERSION='5.2' ENABLE_TRANSITIONS='true' bundle exec rake test
  ACTIVEMODEL_VERSION='5.2' ENABLE_TRANSITIONS='false' bundle exec rake test
fi

if [[ $ruby_v =~ '2.5.' ]] || [[ $ruby_v =~ '2.6.' ]] || [[ $ruby_v =~ '2.7.' ]]; then
  ACTIVEMODEL_VERSION='6.0' bundle update
  ACTIVEMODEL_VERSION='6.0' ENABLE_TRANSITIONS='true' bundle exec rake test
  ACTIVEMODEL_VERSION='6.0' ENABLE_TRANSITIONS='false' bundle exec rake test
fi

bundle update
ENABLE_TRANSITIONS='true' bundle exec rake test
ENABLE_TRANSITIONS='false' bundle exec rake test
