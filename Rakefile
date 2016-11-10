require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.verbose = true

  test_files = FileList['test/**/*_test.rb']

  if RUBY_VERSION == "1.9.3"
    test_files = test_files - %w{test/dry_container_test.rb}

  end

  puts test_files.inspect
  test.test_files = test_files
end
