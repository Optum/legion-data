require 'sequel/extensions/migration'

module Legion
  module Data
    module Migration
      class << self
        def migrate(connection = Legion::Data.connection, path = "#{__dir__}/migrations", **opts)
          Legion::Settings[:data][:migrations][:version] = Sequel::Migrator.run(connection, path, **opts)
          Legion::Logging.info("Legion::Data::Migration ran successfully to version #{Legion::Settings[:data][:migrations][:version]}") # rubocop:disable Layout/LineLength
          Legion::Settings[:data][:migrations][:ran] = true
        end
      end
    end
  end
end
