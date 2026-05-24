# frozen_string_literal: true
#
# Runs all benchmark scenarios with `disable_runtime_checks = false`
# (the default — checks active).
#
#   unset BUNDLE_GEMFILE && ruby checks_enabled.rb /tmp/u_case_enabled.json
#
# Driven via compare.rb; see that file for the side-by-side comparison.

MODE = :enabled

require_relative '_runner'
