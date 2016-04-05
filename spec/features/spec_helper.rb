require 'aruba/rspec'
require 'logger'
require 'pathname'
require 'pry'
require 'simplecov'

TMP_DIR = Pathname.new(File.expand_path('../../../tmp', __FILE__))
FIXTURES_PATH = Pathname.new(File.expand_path('../fixtures/', __FILE__))
CMD_ROOT = TMP_DIR.join('features')
RAILS_CACHE = TMP_DIR.join('rails_app')
RAILS_ROOT = CMD_ROOT.join('current')

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each {|f| require f}

Aruba.configure do |config|
  t = RUBY_PLATFORM == 'java' ? 120 : 7
  config.working_directory = 'tmp/features'
  config.exit_timeout = t
  config.io_wait_timeout = t
end

SimpleCov.command_name 'spec:features'

RSpec.configure do |config|
  Kernel.srand config.seed

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.alias_example_group_to :feature, type: :feature, framework: :ruby
  config.alias_example_group_to :scenario

  config.include Aruba::Api
  config.include CommandLine
  config.include RailsHelpers, framework: :rails

  config.before(:each) do
    set_environment_variable('HONEYBADGER_BACKEND', 'debug')
    set_environment_variable('HONEYBADGER_LOGGING_PATH', 'STDOUT')
  end

  config.before(:all, framework: :rails) do
    FileUtils.rm_r(RAILS_CACHE) if RAILS_CACHE.exist?
  end

  config.before(:each, framework: :rails) do
    unless RAILS_CACHE.exist?
      # This command needs to run in the before(:each) callback to satisfy
      # aruba, but we only want to run it once per suite.
      run_simple("rails new #{ RAILS_CACHE } -O -S -G -J -T --skip-gemfile --skip-bundle", fail_on_error: true)
    end

    # Copying the cached version is faster than generating a new rails app
    # before each scenario.
    FileUtils.cp_r(RAILS_CACHE, RAILS_ROOT)
    cd('current')
  end

  if ENV['BUNDLE_GEMFILE'] =~ /rails/
    config.filter_run_excluding framework: ->(v) { v != :rails }
  elsif ENV['BUNDLE_GEMFILE'] =~ /sinatra/
    config.filter_run_excluding framework: ->(v) { v != :sinatra }
  elsif ENV['BUNDLE_GEMFILE'] =~ /rake/
    config.filter_run_excluding framework: ->(v) { v != :rake }
  else
    config.filter_run_excluding framework: ->(v) { v != :ruby }
  end
end
