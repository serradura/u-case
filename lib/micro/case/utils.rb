# frozen_string_literal: true

module Micro
  class Case
    module Utils
      def self.symbolize_hash_keys(hash)
        if Kind::Of::Hash(hash).respond_to?(:transform_keys)
          hash.transform_keys { |key| key.to_sym rescue key }
        else
          hash.each_with_object({}) do |(k, v), memo|
            key = k.to_sym rescue k

            memo[key] = v
          end
        end
      end

      def self.slice_hash(hash, keys)
        if Kind::Of::Hash(hash).respond_to?(:slice)
          hash.slice(*keys)
        else
          hash.select { |key, _value| keys.include?(key) }
        end
      end
    end
  end
end
