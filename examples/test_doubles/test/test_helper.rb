# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)

require 'minitest/autorun'
require 'mocha/minitest'

# This single line opts the test-side Result factories into the process —
# `Micro::Case::Result::Success.new`, `Result::Failure.new`, and `.to_yield`.
# The gem itself does NOT auto-require this file; test_helper.rb is the
# place to load it.
require 'micro/case/with_test_doubles'

require 'affiliates'
