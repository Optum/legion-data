# frozen_string_literal: true

require 'legion/data/version'
require 'legion/data/settings'
require 'sequel'

require 'legion/data/connection'
require 'legion/data/model'
require 'legion/data/migration'
require_relative 'data/local'

module Legion
  module Data
    class << self
      def setup
        connection_setup
        migrate
        load_models
        setup_cache
        setup_local
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

      def local
        Legion::Data::Local
      end

      def setup_cache
        return if Legion::Settings[:data][:cache][:enabled]

        nil unless defined?(::Legion::Cache)

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
        Legion::Data::Local.shutdown if defined?(Legion::Data::Local) && Legion::Data::Local.connected?
        Legion::Data::Connection.shutdown
      end

      private

      def setup_local
        return if Legion::Settings[:data].dig(:local, :enabled) == false

        Legion::Data::Local.setup
      rescue StandardError => e
        Legion::Logging.warn "Legion::Data::Local failed to setup: #{e.message}" if defined?(Legion::Logging)
      end
    end
  end
end
