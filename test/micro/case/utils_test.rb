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

  def test_slice_hash
    assert_raises_with_message(
      Kind::Error,
      '[] expected to be a kind of Hash'
    ) { Micro::Case::Utils.slice_hash([], []) }

    # --

    hash = { 'a' => 1, 'b' => 2, c: 3 }

    new_hash = Micro::Case::Utils.slice_hash(hash, ['a', 'b', 'c'])

    refute_same(hash, new_hash)

    assert_equal({ 'a' => 1, 'b' => 2 }, new_hash)

    assert_equal({}, Micro::Case::Utils.slice_hash(hash, ['d']))

    if hash.respond_to?(:transform_keys)
      def hash.respond_to?(method)
        method == :slice ? false : super
      end

      new_hash = Micro::Case::Utils.slice_hash(hash, ['a', :c])

      refute_same(hash, new_hash)

      assert_equal({ 'a' => 1, c: 3 }, new_hash)

      assert_equal({}, Micro::Case::Utils.slice_hash(hash, ['d', 'e']))
    end
  end
end
