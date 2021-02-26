require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.verbose = true
  test.test_files = FileList["test/**/*_test.rb"]
end

task :default => %i[test]
