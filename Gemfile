source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

activemodel_version = ENV.fetch('ACTIVEMODEL_VERSION', '6.1.0')

activemodel = case activemodel_version
              when '3.2' then '3.2.22'
              when '5.2' then '5.2.3'
              when '6.0' then '6.0.2'
              end

if activemodel_version < '6.1.0'
  gem 'activemodel', activemodel, require: false
  gem 'activesupport', activemodel, require: false
end

group :test do
  gem 'minitest', activemodel_version < '4.1' ? '~> 4.2' : '~> 5.0'

  simplecov_version = RUBY_VERSION < '2.4.0' ? '~> 0.17.1' : '>= 0.18.5'

  gem 'simplecov', simplecov_version, require: false
end

pry_byebug_version =
  case RUBY_VERSION
  when /\A2.[23]/ then '3.6'
  else '3.9'
  end

pry_version =
  case RUBY_VERSION
  when /\A2.2/ then '0.12.2'
  when /\A2.3/ then '0.12.2'
  else '0.13.1'
  end

group :development, :test do
  gem 'awesome_print', '~> 1.8'

  gem 'byebug', '~> 10.0', '>= 10.0.2' if RUBY_VERSION =~ /\A2.[23]/

  gem 'pry', "~> #{pry_version}"
  gem 'pry-byebug', "~> #{pry_byebug_version}"
end

# Specify your gem's dependencies in u-case.gemspec
gemspec
