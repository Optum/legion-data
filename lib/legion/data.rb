require 'legion/data/version'
require 'legion/data/settings'
require 'sequel'

require 'legion/data/connection'
require 'legion/data/model'
require 'legion/data/migration'

module Legion
  module Data
    class << self
      def setup
        connection_setup
        migrate
        load_models
        setup_cache
      end

      def connection_setup
        return if Legion::Settings[:data][:connected]

        Legion::Data::Connection.setup
      end

      def migrate
        Legion::Data::Migration.migrate
      end

      def load_models
        Legion::Data::Models.load
      end

      def connection
        Legion::Data::Connection.sequel
      end

      def setup_cache
        return if Legion::Settings[:data][:cache][:enabled]

        return unless defined?(::Legion::Cache)

        # Legion::Data::Model::Relationship.plugin :caching, Legion::Cache, ttl: 10
        # Legion::Data::Model::Runner.plugin :caching, Legion::Cache, ttl: 60
        # Legion::Data::Model::Chain.plugin :caching, Legion::Cache, ttl: 60
        # Legion::Data::Model::Function.plugin :caching, Legion::Cache, ttl: 120
        # Legion::Data::Model::Extension.plugin :caching, Legion::Cache, ttl: 120
        # Legion::Data::Model::Node.plugin :caching, Legion::Cache, ttl: 10
        # Legion::Data::Model::TaskLog.plugin :caching, Legion::Cache, ttl: 12
        # Legion::Data::Model::Task.plugin :caching, Legion::Cache, ttl: 10
        # Legion::Data::Model::User.plugin :caching, Legion::Cache, ttl: 120
        # Legion::Data::Model::Group.plugin :caching, Legion::Cache, ttl: 120
        # Legion::Logging.info 'Legion::Data connected to Legion::Cache'
      end

      def shutdown
        Legion::Data::Connection.shutdown
      end
    end
  end
end
