#!/bin/bash

cd $(dirname $0)

echo u_case_v3-1-0.rb
echo '----------------'
ruby u_case_v3-1-0.rb | head -n 3

echo u_case_v2-6-0.rb
echo '----------------'
ruby u_case_v2-6-0.rb | head -n 3

echo u_case_v2-0-0.rb
echo '----------------'
ruby u_case_v2-0-0.rb | head -n 3

echo interactor.rb
echo '-------------'
ruby interactor.rb | head -n 3

echo trailblazer_operations.rb
echo '-------------------------'
ruby trailblazer_operations.rb | head -n 3
