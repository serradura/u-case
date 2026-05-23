source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in u-case.gemspec
gemspec

gem "rake", "~> 13.0"

group :test do
  gem "simplecov", "~> 0.22.0", require: false
end

group :development, :test do
  gem "awesome_print"
end
