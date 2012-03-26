#!/usr/bin/env rake
require 'opentox-client'
require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*.rb'] - FileList["test/setup.rb"]
  t.verbose = true
end
