# frozen_string_literal: true

require 'sequel'
require 'sequel/extensions/migration'

module Legion
  module Data
    module Local
      class << self
        attr_reader :connection, :db_path

        def setup(database: nil, **)
          return if @connected

          db_file = database || local_settings[:database] || 'legionio_local.db'
          @db_path = db_file
          @connection = ::Sequel.sqlite(db_file)
          @connected = true
          run_migrations
          Legion::Logging.info "Legion::Data::Local connected to #{db_file}" if defined?(Legion::Logging)
        end

        def shutdown
          @connection&.disconnect
          @connection = nil
          @connected = false
        end

        def connected?
          @connected == true
        end

        def register_migrations(name:, path:)
          @registered_migrations ||= {}
          @registered_migrations[name] = path
          run_single_migration(name, path) if connected?
        end

        def registered_migrations
          @registered_migrations || {}
        end

        def model(table_name)
          raise 'Legion::Data::Local not connected' unless connected?

          ::Sequel::Model(connection[table_name])
        end

        def reset!
          @connection = nil
          @connected = false
          @db_path = nil
          @registered_migrations = nil
        end

        private

        def run_migrations
          return unless local_settings.dig(:migrations, :auto_migrate) != false

          registered_migrations.each do |name, path|
            run_single_migration(name, path)
          end
        end

        def run_single_migration(name, path)
          return unless local_settings.dig(:migrations, :auto_migrate) != false
          return unless File.directory?(path)

          table = :"schema_migrations_#{name}"
          ::Sequel::TimestampMigrator.new(@connection, path, table: table).run
        rescue StandardError => e
          Legion::Logging.warn "Local migration failed for #{path}: #{e.message}" if defined?(Legion::Logging)
        end

        def local_settings
          return {} unless defined?(Legion::Settings)

          Legion::Settings[:data]&.dig(:local) || {}
        end
      end
    end
  end
end
