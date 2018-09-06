task default: [:package_gem]
task package_gem: [:test, :yard]

task :tasks do
  puts Rake.application.tasks
end

task :package_gem do
  command = "gem build cucumber-api-assistant.gemspec"
  sh command
  if $?.exitstatus != 0
    fail "Command #{command} failed!"
  end
end

task :test do
  command = "cucumber --tags ~@failing snippets_dir=. log_level=debug"

  sh command
  if $?.exitstatus != 0
    fail "Command #{command} failed!"
  end
end

require 'yard'

YARD::Rake::YardocTask.new do |t|
 t.files   = ['lib/**/*.rb']
 t.options = ['--readme', 'readme.md', 
              '--output-dir', 'docs',
              '--markup', 'markdown',
              '--plugin', 'yard-cucumber',
              '--private']
 # t.stats_options = ['--list-undoc']
 puts ""
end

require 'rake/clean'

CLEAN.include 'docs'
CLEAN.include 'documentation'
CLEAN.include 'logs'
CLEAN.include '*.gem'
CLEAN.include '*Gemfile.lock'
