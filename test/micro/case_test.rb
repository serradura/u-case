require 'test_helper'

class Micro::CaseTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Micro::Case::VERSION
  end
end
