# frozen_string_literal: true
#
# Runs all benchmark scenarios with `disable_runtime_checks = true`
# (checks turned off).
#
#   unset BUNDLE_GEMFILE && ruby checks_disabled.rb /tmp/u_case_disabled.json
#
# Driven via compare.rb; see that file for the side-by-side comparison.

MODE = :disabled

require_relative '_runner'
