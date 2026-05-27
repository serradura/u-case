# frozen_string_literal: true

# Shared ActiveJob setup for the Micro::Case::ActiveJob test suite.
#
# Loads ActiveJob, installs the :test adapter (so jobs land in
# ActiveJob::Base.queue_adapter.enqueued_jobs instead of being shipped off
# to a real backend), and pulls in the runner.

require 'active_job'
require 'active_job/test_helper'

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(IO::NULL) if ActiveJob::Base.respond_to?(:logger=)

require 'micro/case/active_job'
