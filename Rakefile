require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

require "appraisal/task"

Appraisal::Task.new

desc "Run the full test suite in all supported Rails versions (both transitions modes)"
task :matrix do
  appraisals =
    if RUBY_VERSION < "3.1"
      ["rails-6-0", "rails-6-1"]
    elsif RUBY_VERSION < "3.2"
      ["rails-7-0", "rails-7-1", "rails-7-2"]
    elsif RUBY_VERSION < "3.3"
      ["rails-7-0", "rails-7-1", "rails-7-2", "rails-8-0"]
    elsif RUBY_VERSION < "3.4"
      ["rails-7-0", "rails-7-1", "rails-7-2", "rails-8-0", "rails-8-1", "rails-edge"]
    elsif RUBY_VERSION < "4.0"
      ["rails-7-2", "rails-8-0", "rails-8-1", "rails-edge"]
    else
      ["rails-8-1", "rails-edge"]
    end

  appraisals.each do |appraisal|
    ["true", "false"].each do |transitions|
      sh({"ENABLE_TRANSITIONS" => transitions}, "bundle exec appraisal #{appraisal} rake test")
    end
  end
end

task default: :test
