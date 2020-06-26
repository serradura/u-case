# frozen_string_literal: true

require 'securerandom'

module InactiveRecord
  class Base
    attr_reader :id

    def self.__relation; (@relation ||= []); end

    def self.all; __relation.to_a; end

    def self.count; __relation.size; end

    def self.delete_all; @relation = []; end

    def self.find_by_id(id)
      __relation.find { |rec| rec.id == id }
    end

    def new_record?; id.nil?; end

    private

      def save_new_record
        if new_record?
          @id = SecureRandom.uuid

          yield

          self.class.__relation << self
        end

        true
      end
  end
end
