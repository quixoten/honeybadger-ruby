require 'logger'
require 'pathname'
require 'pry'
require 'rspec/its'
require 'simplecov'

# Minimum ENV required for Rails in production.
ENV['RAILS_ENV'] = 'production'
ENV['SECRET_KEY_BASE'] = '13556183a3c710cbc76f2a95569ae03d981714486d67ce828ed896a167bc2e8ea17855d3bccc49c8c12228adf319dd06211f60cb9bbcc010ec13709b2718f1cb'

# We don't want this bleeding through in tests. (i.e. from CircleCi)
ENV['RACK_ENV'] = nil

TMP_DIR = Pathname.new(File.expand_path('../../../tmp', __FILE__))
FIXTURES_PATH = Pathname.new(File.expand_path('../fixtures/', __FILE__))
NULL_LOGGER = Logger.new('/dev/null')
NULL_LOGGER.level = Logger::Severity::DEBUG

SimpleCov.command_name 'spec:units'

# Soft dependencies
%w(rack binding_of_caller).each do |lib|
  begin
    require lib
  rescue LoadError
    puts "Excluding specs for #{ lib }"
  end
end

begin
  require 'i18n'
  I18n.enforce_available_locales = false
rescue LoadError
  nil
end

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each {|f| require f}

RSpec.configure do |config|
  Kernel.srand config.seed

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.include Helpers

  config.before(:each) do
    defined?(Honeybadger.config) and
      Honeybadger.config = Honeybadger::Config::Default.new(backend: 'test'.freeze)

    defined?(Honeybadger::Config::Env) and
      ENV.each_pair do |k,v|
      next unless k.match(Honeybadger::Config::Env::CONFIG_KEY)
      ENV.delete(k)
    end
  end

  config.after(:each) do
    defined?(Honeybadger.worker) && Honeybadger.worker and
      Honeybadger.worker.stop

    Thread.current[:__honeybadger_context] = nil
  end

  begin
    require 'sham_rack'
  rescue LoadError
    puts 'Excluding Rack specs: sham_rack is not available.'
    config.exclude_pattern = 'spec/unit/honeybadger/rack/*_spec.rb'
  end
end
