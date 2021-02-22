# frozen_string_literal: true

module Micro::Case::Utils

  module Hashes
    def self.respond_to?(hash, method)
      Kind::Hash[hash].respond_to?(method)
    end

    def self.symbolize_keys(hash)
      return hash.transform_keys { |key| key.to_sym rescue key } if respond_to?(hash, :transform_keys)

      hash.each_with_object({}) do |(k, v), memo|
        key = k.to_sym rescue k
        memo[key] = v
      end
    end

    def self.stringify_keys(hash)
      return hash.transform_keys(&:to_s) if respond_to?(hash, :transform_keys)

      hash.each_with_object({}) { |(k, v), memo| memo[k.to_s] = v }
    end

    def self.slice(hash, keys)
      return hash.slice(*keys) if respond_to?(hash, :slice)

      hash.select { |key, _value| keys.include?(key) }
    end
  end

end
