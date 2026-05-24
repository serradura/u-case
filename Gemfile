source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in u-case.gemspec
gemspec

gem "rake", "~> 13.0"

group :test do
  gem "simplecov", "~> 0.22.0", require: false
  gem "minitest", (RUBY_VERSION >= "4.0") ? "~> 6.0" : "~> 5.27" if RUBY_VERSION >= "3.1"
  gem "ostruct", "~> 0.6.3" if RUBY_VERSION >= "3.5"
end

group :development, :test do
  gem "awesome_print"
end

group :development do
  gem "ruby-lsp", require: false if RUBY_VERSION >= "3.0"
end
