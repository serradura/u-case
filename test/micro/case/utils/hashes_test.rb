require 'test_helper'

class Micro::Case
  class Utils::HashesTest < Minitest::Test
    def test_symbolize_hash_keys
      assert_raises_with_message(
        Kind::Error,
        '[] expected to be a kind of Hash'
      ) { Utils::Hashes.symbolize_keys([]) }

      # --

      hash = { 'a' => 1 }

      new_hash = Utils::Hashes.symbolize_keys(hash)

      refute_same(hash, new_hash)
      assert_equal({ a: 1 }, new_hash)

      if hash.respond_to?(:transform_keys)
        def hash.respond_to?(method)
          method == :transform_keys ? false : super
        end

        new_hash = Utils::Hashes.symbolize_keys(hash)

        refute_same(hash, new_hash)
        assert_equal({ a: 1 }, new_hash)
      end
    end

    def test_slice_hash
      assert_raises_with_message(
        Kind::Error,
        '[] expected to be a kind of Hash'
      ) { Utils::Hashes.slice([], []) }

      # --

      hash = { 'a' => 1, 'b' => 2, c: 3 }

      new_hash = Utils::Hashes.slice(hash, ['a', 'b', 'c'])

      refute_same(hash, new_hash)

      assert_equal({ 'a' => 1, 'b' => 2 }, new_hash)

      assert_equal({}, Utils::Hashes.slice(hash, ['d']))

      if hash.respond_to?(:transform_keys)
        def hash.respond_to?(method)
          method == :slice ? false : super
        end

        new_hash = Utils::Hashes.slice(hash, ['a', :c])

        refute_same(hash, new_hash)

        assert_equal({ 'a' => 1, c: 3 }, new_hash)

        assert_equal({}, Utils::Hashes.slice(hash, ['d', 'e']))
      end
    end
  end
end
