# frozen_string_literal: true

require 'digest'

class User < InactiveRecord::Base
  attr_reader :password_hash
  attr_accessor :name

  def initialize(options = {})
    @name = options[:name]
    @password = options[:password]
  end

  def invalid?
    name.empty? || @password.empty?
  end

  def save
    return false if invalid?

    self.name = name

    save_new_record do
      @password_hash = Digest::SHA256.hexdigest(@password)
    end
  end

  def wrong_password?(value)
    password_hash != Digest::SHA256.hexdigest(value)
  end
end
