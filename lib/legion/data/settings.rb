module Legion
  module Data
    module Settings
      def self.default
        {
          connected: false,
          cache: cache,
          connection: connection,
          creds: creds,
          migrations: migrations,
          models: models,
          connect_on_start: true
        }
      end

      def self.models
        {
          continue_on_load_fail: false,
          autoload: true
        }
      end

      def self.migrations
        {
          continue_on_fail: false,
          auto_migrate: true,
          ran: false,
          version: nil
        }
      end

      def self.connection
        {
          log: false,
          log_connection_info: false,
          log_warn_duration: 1,
          sql_log_level: 'debug',
          max_connections: 10,
          preconnect: false
        }
      end

      def self.creds
        {
          username: 'legion',
          password: 'legion',
          database: 'legionio',
          host: '127.0.0.1',
          port: 3306
        }
      end

      def self.cache
        {
          connected: false,
          auto_enable: Legion::Settings[:cache][:connected],
          ttl: 60
        }
      end
    end
  end
end

begin
  Legion::Settings.merge_settings('data', Legion::Data::Settings.default) if Legion.const_defined?('Settings')
rescue StandardError => e
  Legion::Logging.fatal(e.message) if Legion::Logging.method_defined?(:fatal)
end
