source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

group :test do
  gem 'minitest'

  gem 'simplecov', require: false

  gem 'sqlite3'
  gem 'activerecord', require: 'active_record'
end

group :development, :test do
  gem 'awesome_print'

  gem 'byebug'

  gem 'pry'
  gem 'pry-byebug'
end

# Specify your gem's dependencies in u-case.gemspec
gemspec
