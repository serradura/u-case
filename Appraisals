if RUBY_VERSION < "3.1"
  appraise "rails-6-0" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"

      gem "sqlite3", "~> 1.7"
      gem "minitest", "5.26.1"
      gem "activerecord", "~> 6.0.0", require: "active_record"
    end
  end

  appraise "rails-6-1" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"

      gem "sqlite3", "~> 1.7"
      gem "minitest", "5.26.1"
      gem "activerecord", "~> 6.1.0", require: "active_record"
    end
  end
end

if RUBY_VERSION >= "2.7" && RUBY_VERSION < "3.4"
  appraise "rails-7-0" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"
      gem "securerandom", "~> 0.3.2"

      gem "sqlite3", "~> 1.7"
      gem "minitest", "5.26.1"
      gem "activerecord", "~> 7.0.0", require: "active_record"
    end
  end

  appraise "rails-7-1" do
    group :test do
      gem "logger", "~> 1.6", ">= 1.6.6"
      gem "stringio", "~> 3.2"
      gem "securerandom", "~> 0.3.2"

      gem "sqlite3", "~> 1.7"
      gem "minitest", "5.26.1"
      gem "activerecord", "~> 7.1.0", require: "active_record"
    end
  end
end

if RUBY_VERSION >= "3.1" && RUBY_VERSION < "4.0"
  appraise "rails-7-2" do
    group :test do
      gem "sqlite3", "~> 2.8", ">= 2.8.1"
      gem "minitest", "~> 5.27"
      gem "activerecord", "~> 7.2.0", require: "active_record"
    end
  end
end

if RUBY_VERSION >= "3.2" && RUBY_VERSION < "4.0"
  appraise "rails-8-0" do
    group :test do
      gem "sqlite3", "~> 2.9"
      gem "ostruct", "~> 0.6.3"
      gem "minitest", "~> 5.27"
      gem "activerecord", "~> 8.0.0", require: "active_record"
    end
  end
end

if RUBY_VERSION >= "3.3.0"
  minitest_version = (RUBY_VERSION >= "4.0.0") ? "~> 6.0" : "~> 5.27"

  appraise "rails-8-1" do
    group :test do
      gem "sqlite3", "~> 2.9"
      gem "ostruct", "~> 0.6.3"
      gem "minitest", minitest_version
      gem "activerecord", "~> 8.1.0", require: "active_record"
    end
  end

  appraise "rails-edge" do
    group :test do
      gem "sqlite3", "~> 2.9"
      gem "ostruct", "~> 0.6.3"
      gem "minitest", minitest_version
      gem "activerecord", github: "rails/rails", branch: "main", require: "active_record"
    end
  end
end
