# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require "irb"
Bundler::GemHelper.install_tasks

require "rake/testtask"

task default: [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

desc "Start a console with the gem"
task :console do
  ARGV.clear
  puts "ExceptionNotification #{ExceptionNotification::VERSION} loaded."
  IRB.start
end
