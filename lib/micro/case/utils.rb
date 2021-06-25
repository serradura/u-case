# frozen_string_literal: true

module Micro::Case::Utils

  module Hashes
    extend self

    def respond_to?(hash, method)
      Kind::Hash[hash].respond_to?(method)
    end

    def symbolize_keys(hash)
      return hash.transform_keys { |key| key.to_sym rescue key } if respond_to?(hash, :transform_keys)

      hash.each_with_object({}) do |(k, v), memo|
        key = k.to_sym rescue k
        memo[key] = v
      end
    end

    def stringify_keys(hash)
      return hash.transform_keys(&:to_s) if respond_to?(hash, :transform_keys)

      hash.each_with_object({}) { |(k, v), memo| memo[k.to_s] = v }
    end

    def slice(hash, keys)
      return hash.slice(*keys) if respond_to?(hash, :slice)

      hash.select { |key, _value| keys.include?(key) }
    end

    def fetch_values(hash, keys, &block)
      return hash.fetch_values(*keys, &block) if respond_to?(hash, :fetch_values)

      result = []

      keys.each do |key|
        result << hash.fetch(key, &block)
      end

      result
    end
  end

end
