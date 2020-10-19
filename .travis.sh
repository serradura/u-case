#!/bin/bash

ruby_v=$(ruby -v)

ACTIVERECORD_VERSION='3.2' bundle update
ACTIVERECORD_VERSION='3.2' ENABLE_TRANSITIONS='false' bundle exec rake test
ACTIVERECORD_VERSION='3.2' ENABLE_TRANSITIONS='true' bundle exec rake test

ACTIVERECORD_VERSION='4.0' bundle update
ACTIVERECORD_VERSION='4.0' bundle exec rake test

ACTIVERECORD_VERSION='4.1' bundle update
ACTIVERECORD_VERSION='4.1' bundle exec rake test

ACTIVERECORD_VERSION='4.2' bundle update
ACTIVERECORD_VERSION='4.2' bundle exec rake test

ACTIVERECORD_VERSION='5.0' bundle update
ACTIVERECORD_VERSION='5.0' bundle exec rake test

ACTIVERECORD_VERSION='5.1' bundle update
ACTIVERECORD_VERSION='5.1' bundle exec rake test

if [[ ! $ruby_v =~ '2.2.0' ]]; then
  ACTIVERECORD_VERSION='5.2' bundle update
  ACTIVERECORD_VERSION='5.2' ENABLE_TRANSITIONS='false' bundle exec rake test
  ACTIVERECORD_VERSION='5.2' ENABLE_TRANSITIONS='true' bundle exec rake test
fi

if [[ $ruby_v =~ '2.5.' ]] || [[ $ruby_v =~ '2.6.' ]] || [[ $ruby_v =~ '2.7.' ]]; then
  ACTIVERECORD_VERSION='6.0' bundle update
  ACTIVERECORD_VERSION='6.0' ENABLE_TRANSITIONS='false' bundle exec rake test
  ACTIVERECORD_VERSION='6.0' ENABLE_TRANSITIONS='true' bundle exec rake test
fi

bundle update
ENABLE_TRANSITIONS='false' bundle exec rake test
ENABLE_TRANSITIONS='true' bundle exec rake test
