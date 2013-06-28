# encoding: utf-8
require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

$:.unshift File.expand_path("../lib", __FILE__)

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts  = %w[-w -r./capture_warnings]
  t.rspec_opts = %w[--color]
end

task default: [:spec]
