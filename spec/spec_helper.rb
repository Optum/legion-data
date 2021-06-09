# begin
#   require 'simplecov'
#   SimpleCov.start do
#     add_filter '/spec/'
#     add_group 'Models', 'lib/legion/data/models'
#     add_group 'Migrations', 'lib/legion/data/migrations'
#     add_group 'Connections', 'lib/legion/data/connections'
#   end
# rescue LoadError
#   puts 'Failed to load file for coverage reports, continuing without it'
# end

require 'bundler/setup'
require 'legion/logging'
require 'legion/settings'
Legion::Logging.setup(log_file: './legion.log', level: 'fatal')
Legion::Settings.load
require 'legion/data'

Legion::Data.setup

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
