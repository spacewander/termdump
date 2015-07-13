#!/usr/bin/env rake
# encoding: UTF-8

require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = false
  # so we can type `rake TEST="xxx"` instead of `rake TEST="test/test_xxx.rb"`
  test = ENV['TEST']
  unless test.nil?
    ENV['TEST'] = 'test/test_' + test unless test.start_with? 'test/test_'
    ENV['TEST'] += '.rb' unless test.end_with? '.rb'
  end
end

task :default => :test
