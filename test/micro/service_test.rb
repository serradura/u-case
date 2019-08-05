require "test_helper"

class Micro::ServiceTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Micro::Service::VERSION
  end
end
