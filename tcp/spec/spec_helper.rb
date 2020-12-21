require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end
