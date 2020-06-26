require 'test_helper'

class Micro::Case::UtilsTest < Minitest::Test
  def test_symbolize_hash_keys
    assert_raises_with_message(
      Kind::Error,
      '[] expected to be a kind of Hash'
    ) { Micro::Case::Utils.symbolize_hash_keys([]) }

    # --

    hash = { 'a' => 1 }

    new_hash = Micro::Case::Utils.symbolize_hash_keys(hash)

    refute_same(hash, new_hash)
    assert_equal({ a: 1 }, new_hash)

    if hash.respond_to?(:transform_keys)
      def hash.respond_to?(method)
        method == :transform_keys ? false : super
      end

      new_hash = Micro::Case::Utils.symbolize_hash_keys(hash)

      refute_same(hash, new_hash)
      assert_equal({ a: 1 }, new_hash)
    end
  end
end
