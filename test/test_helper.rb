require 'simplecov'

SimpleCov.start do
  add_filter "/test/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'micro/service'

require 'minitest/autorun'
