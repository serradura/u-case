# frozen_string_literal: true

class Todo < InactiveRecord::Base
  attr_accessor :description, :done, :user_id

  def self.find_by_id_and_user_id(id, user_id)
    all.find { |todo| todo.id == id && todo.user_id && user_id }
  end

  def initialize(options = {})
    @user_id = options[:user_id]
    @description = options[:description]
  end

  def invalid?
    description.empty? || user_id.empty?
  end

  def save
    return false if invalid?

    self.description = description

    save_new_record { @done = done? }
  end

  def pending?; !done; end

  def done?; !pending?; end
end

