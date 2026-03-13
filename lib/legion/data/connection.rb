require 'sequel'

module Legion
  module Data
    module Connection
      ADAPTERS = %i[sqlite mysql2 postgres].freeze

      class << self
        attr_accessor :sequel

        def adapter
          @adapter ||= Legion::Settings[:data][:adapter]&.to_sym || :sqlite
        end

        def setup
          @sequel = if adapter == :sqlite
                      ::Sequel.sqlite(sqlite_path)
                    else
                      ::Sequel.connect(adapter: adapter, **creds_builder)
                    end
          Legion::Settings[:data][:connected] = true
          configure_logging
        end

        def shutdown
          @sequel&.disconnect
          Legion::Settings[:data][:connected] = false
        end

        def creds_builder(final_creds = {})
          final_creds.merge! Legion::Data::Settings.creds(adapter)
          final_creds.merge! Legion::Settings[:data][:creds] if Legion::Settings[:data][:creds].is_a? Hash

          return final_creds if Legion::Settings[:vault].nil?

          if Legion::Settings[:vault][:connected] && ::Vault.sys.mounts.key?(:database)
            temp_vault_creds = Legion::Crypt.read('database/creds/legion')
            final_creds[:user] = temp_vault_creds[:username]
            final_creds[:password] = temp_vault_creds[:password]
          end

          final_creds
        end

        private

        def sqlite_path
          Legion::Settings[:data][:creds][:database] || 'legionio.db'
        end

        def configure_logging
          return if Legion::Settings[:data][:connection].nil? || Legion::Settings[:data][:connection][:log].nil?

          @sequel.logger = Legion::Logging
          @sequel.sql_log_level = Legion::Settings[:data][:connection][:sql_log_level]
          @sequel.log_warn_duration = Legion::Settings[:data][:connection][:log_warn_duration]
        end
      end
    end
  end
end
