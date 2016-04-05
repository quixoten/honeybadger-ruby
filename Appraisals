appraise 'standalone' do
end

if RUBY_PLATFORM !~ /java/
  appraise 'binding_of_caller' do
    gem 'binding_of_caller'
  end
end

appraise 'rake' do
  gem 'rake'
end

appraise 'thor' do
  gem 'thor'
end

appraise 'rack' do
  gem 'rack'
  gem 'sham_rack', require: false
end

appraise 'sinatra' do
  gem 'sinatra'
  # Temporary until https://github.com/sinatra/sinatra/pull/907 is released
  gem 'rack', '~> 1.5.2'
end

appraise 'delayed_job' do
  gem 'delayed_job'
end

appraise 'rails3.2' do
  gem 'rails', '~> 3.2.12'
  gem 'better_errors', require: false, platforms: [:ruby_20, :ruby_21]
  gem 'rack-mini-profiler', require: false
  gem 'capistrano', '~> 2.0'
end

appraise 'rails4.0' do
  gem 'rails', '~> 4.0.0'
  gem 'capistrano', '~> 3.0'
  gem 'better_errors', require: false, platforms: [:ruby_20, :ruby_21]
  gem 'rack-mini-profiler', require: false
end

appraise 'rails4.1' do
  gem 'rails', '~> 4.1.4'
  gem 'capistrano', '~> 3.0'
  gem 'better_errors', require: false, platforms: [:ruby_20, :ruby_21]
  gem 'rack-mini-profiler', require: false
end

appraise 'rails4.2' do
  gem 'rails', '~> 4.2.4'
  gem 'capistrano', '~> 3.0'
  gem 'better_errors', require: false, platforms: [:ruby_20, :ruby_21]
  gem 'rack-mini-profiler', require: false
end

# The latest officially supported Rails release
appraise 'rails' do
  gem 'rails', github: 'rails/rails'
  gem 'rack', github: 'rack/rack'
  gem 'arel', github: 'rails/arel'
  gem 'capistrano', '~> 3.0'
  gem 'better_errors', require: false, platforms: [:ruby_20, :ruby_21]
end
