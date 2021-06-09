require 'sequel'

module Legion
  module Data
    module Connection
      class << self
        attr_accessor :sequel

        def adapter
          @adapter ||= RUBY_ENGINE == 'jruby' ? :jdbc : :mysql2
        end

        def setup
          @sequel = if adapter == :mysql2
                      ::Sequel.connect(adapter: adapter, **creds_builder)
                    else
                      ::Sequel.connect("jdbc:mysql://#{creds_builder[:host]}:#{creds_builder[:port]}/#{creds_builder[:database]}?user=#{creds_builder[:username]}&password=#{creds_builder[:password]}&serverTimezone=UTC") # rubocop:disable Layout/LineLength
                    end
          Legion::Settings[:data][:connected] = true
          return if Legion::Settings[:data][:connection].nil? || Legion::Settings[:data][:connection][:log].nil?

          @sequel.logger = Legion::Logging
          @sequel.sql_log_level = Legion::Settings[:data][:connection][:sql_log_level]
          @sequel.log_warn_duration = Legion::Settings[:data][:connection][:log_warn_duration]
        end

        def shutdown
          @sequel&.disconnect
          Legion::Settings[:data][:connected] = false
        end

        def creds_builder(final_creds = {})
          final_creds.merge! Legion::Data::Settings.creds
          final_creds.merge! Legion::Settings[:data][:creds] if Legion::Settings[:data][:creds].is_a? Hash

          # if Legion::Settings[:data][:connection][:max_connections].is_a? Integer
          #   final_creds[:max_connections] = Legion::Settings[:data][:connection][:max_connections]
          # end

          # final_creds[:preconnect] = :concurrently if Legion::Settings[:data][:connection][:preconnect]

          return final_creds if Legion::Settings[:vault].nil?

          if Legion::Settings[:vault][:connected] && ::Vault.sys.mounts.key?(:database)
            temp_vault_creds = Legion::Crypt.read('database/creds/legion')
            final_creds[:user] = temp_vault_creds[:username]
            final_creds[:password] = temp_vault_creds[:password]
          end

          final_creds
        end

        def default_creds
          {
            host: '127.0.0.1',
            port: 3306,
            username: 'legion',
            password: 'legion',
            database: 'legion',
            max_connections: 4
          }
        end
      end
    end
  end
end
