require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
  test.verbose = true
  test.test_files = FileList["test/**/*_test.rb"] - FileList["test/isolated/**"]
end

task :default => %i[test]

Rake::TestTask.new(:test_configuration) do |test|
  test.libs << "test"
  test.verbose = true
  test.test_files = FileList["test/isolated/**/*_test.rb"]
end
