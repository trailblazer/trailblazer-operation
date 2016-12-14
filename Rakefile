require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.verbose = true

  test_files = FileList['test/*_test.rb']

  if    RUBY_VERSION == "1.9.3"
    test_files = test_files - %w{test/dry_container_test.rb test/2.1.0-pipetree_test.rb  test/2.0.0-pipetree_test.rb}
  elsif RUBY_VERSION == "2.0.0"
    test_files = test_files - %w{test/dry_container_test.rb test/2.1.0-pipetree_test.rb}
  end

  test.test_files = test_files
end
