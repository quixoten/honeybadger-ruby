require 'rspec/its'
require 'pathname'
require 'logger'
require 'pry'
require 'simplecov'
require 'aruba/rspec'

# Minimum ENV required for Rails in production.
ENV['RAILS_ENV'] = 'production'
ENV['SECRET_KEY_BASE'] = '13556183a3c710cbc76f2a95569ae03d981714486d67ce828ed896a167bc2e8ea17855d3bccc49c8c12228adf319dd06211f60cb9bbcc010ec13709b2718f1cb'

# We don't want this bleeding through in tests. (i.e. from CircleCi)
ENV['RACK_ENV'] = nil

TMP_DIR = Pathname.new(File.expand_path('../../tmp', __FILE__))
FIXTURES_PATH = Pathname.new(File.expand_path('../fixtures/', __FILE__))
CMD_ROOT = TMP_DIR.join('features')
RAILS_CACHE = TMP_DIR.join('rails_app')
RAILS_ROOT = CMD_ROOT.join('current')
NULL_LOGGER = Logger.new('/dev/null')
NULL_LOGGER.level = Logger::Severity::DEBUG

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

# Aruba configuration.
Aruba.configure do |config|
  t = RUBY_PLATFORM == 'java' ? 120 : 7
  config.working_directory = 'tmp/features'
  config.exit_timeout = t
  config.io_wait_timeout = t
end

# Require files in spec/support/ and its subdirectories.
Dir[File.expand_path('../../spec/support/**/*.rb', __FILE__)].each {|f| require f}

# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    # Enable only the newer, non-monkey-patching expect syntax.
    mocks.syntax = :expect

    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended.
    mocks.verify_partial_doubles = true
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

  # Feature specs
  config.alias_example_group_to :feature, type: :feature, framework: :ruby
  config.alias_example_group_to :scenario

  config.include Aruba::Api, type: :feature
  config.include CommandLine, type: :feature
  config.include RailsHelpers, type: :feature, framework: :rails

  config.before(:each, type: :feature) do
    set_environment_variable('HONEYBADGER_BACKEND', 'debug')
    set_environment_variable('HONEYBADGER_LOGGING_PATH', 'STDOUT')
  end

  config.before(:all, type: :feature, framework: :rails) do
    FileUtils.rm_r(RAILS_CACHE) if RAILS_CACHE.exist?
  end

  config.before(:each, type: :feature, framework: :rails) do
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

  begin
    require 'sham_rack'
  rescue LoadError
    puts 'Excluding Rack specs: sham_rack is not available.'
    config.exclude_pattern = 'spec/unit/honeybadger/rack/*_spec.rb'
  end
end


if ENV['CIRCLECI']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
elsif !ENV['GUARD']
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
  end
end
