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
  gem 'simplecov', require: false
end

# Specify your gem's dependencies in u-case.gemspec
gemspec
