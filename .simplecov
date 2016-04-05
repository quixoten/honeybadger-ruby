if ENV['COVERAGE']
  if ENV['CIRCLECI']
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  else
    SimpleCov.start do
      add_filter '/spec/'
      add_filter '/vendor/'
    end
  end
end
