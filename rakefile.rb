require "bundler/gem_tasks"
require "rspec/core/rake_task"

task default: %w(render:spec)

namespace :render do
  RSpec::Core::RakeTask.new(:spec) do |config|
    config.verbose = false
    config.rspec_opts = ["--order rand"]
  end
end
