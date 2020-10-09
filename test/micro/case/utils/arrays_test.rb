require 'test_helper'

class Micro::Case
  class Utils::ArraysTest < Minitest::Test
    def test_flatten_and_compact
      assert_raises_with_message(
        Kind::Error,
        '{} expected to be a kind of Array'
      ) { Utils::Arrays.flatten_and_compact({}) }

      # --

      array1 = []
      array2 = [nil]
      array3 = [[nil]]

      [array1, array2, array3].each do |array|
        handled = Utils::Arrays.flatten_and_compact(array)

        assert_equal([], handled)
        refute_same(array, handled)
      end

      # -

      array4 = [1]
      array5 = [1, nil]
      array6 = [[1], nil]
      array7 = [[[1], nil]]
      array8 = [[[1], [nil]]]

      [array4, array5, array6, array7, array8].each do |array|
        handled = Utils::Arrays.flatten_and_compact(array)

        assert_equal([1], handled)
        refute_same(array, handled)
      end
    end
  end
end
