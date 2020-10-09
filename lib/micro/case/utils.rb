# frozen_string_literal: true

module Micro
  class Case
    module Utils

      module Hashes
        def self.respond_to?(hash, method)
          Kind.of(Hash, hash).respond_to?(method)
        end

        def self.symbolize_keys(hash)
          if respond_to?(hash, :transform_keys)
            hash.transform_keys { |key| key.to_sym rescue key }
          else
            hash.each_with_object({}) do |(k, v), memo|
              key = k.to_sym rescue k
              memo[key] = v
            end
          end
        end

        def self.slice(hash, keys)
          return hash.slice(*keys) if respond_to?(hash, :slice)

          hash.select { |key, _value| keys.include?(key) }
        end
      end

    end
  end
end
