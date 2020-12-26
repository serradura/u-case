source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

activerecord_version = ENV.fetch('ACTIVERECORD_VERSION', '6.2')

activerecord = case activerecord_version
              when '3.2' then '3.2.22'
              when '4.0' then '4.0.13'
              when '4.1' then '4.1.16'
              when '4.2' then '4.2.11'
              when '5.0' then '5.0.7'
              when '5.1' then '5.1.7'
              when '5.2' then '5.2.3'
              when '6.0' then '6.0.3'
              when '6.1' then '6.1.0'
              end

simplecov_version =
  case RUBY_VERSION
  when /\A2.[23]/ then '~> 0.17.1'
  when /\A2.4/ then '~> 0.18.5'
  else '~> 0.19'
  end

group :test do
  gem 'minitest', activerecord_version < '4.1' ? '~> 4.2' : '~> 5.0'

  gem 'simplecov', simplecov_version, require: false

  if activerecord
    sqlite3 =
      case activerecord
      when /\A6\.(0|1)/, nil then '~> 1.4.0'
      else '~> 1.3.0'
      end

    gem 'sqlite3', sqlite3
    gem 'activerecord', activerecord, require: 'active_record'
  end
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
