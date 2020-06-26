# frozen_string_literal: true

require 'digest'

class User < InactiveRecord::Base
  attr_reader :password_hash
  attr_accessor :email

  def self.find_by_email(email)
    __relation.find { |rec| rec.email == email }
  end

  def initialize(options = {})
    @email = options[:email]
    @password = options[:password]
  end

  def invalid?
    email.empty? || @password.empty?
  end

  def save
    return false if invalid?

    self.email = email

    save_new_record do
      @password_hash = Digest::SHA256.hexdigest(@password)
    end
  end

  def wrong_password?(value)
    password_hash != Digest::SHA256.hexdigest(value)
  end
end
