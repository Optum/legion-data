# frozen_string_literal: true

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
                      begin
                        ::Sequel.connect(adapter: adapter, **creds_builder)
                      rescue StandardError => e
                        raise unless dev_fallback?

                        if defined?(Legion::Logging)
                          Legion::Logging.warn(
                            "Shared DB unreachable (#{e.message}), dev_mode fallback to SQLite"
                          )
                        end
                        @adapter = :sqlite
                        ::Sequel.sqlite(sqlite_path)
                      end
                    end
          Legion::Settings[:data][:connected] = true
          configure_logging
        end

        def shutdown
          @sequel&.disconnect
          Legion::Settings[:data][:connected] = false
        end

        def merge_tls_creds(creds, adapter:, port:)
          return creds if adapter == :sqlite
          return creds unless defined?(Legion::Crypt::TLS)

          tls = Legion::Crypt::TLS.resolve(data_tls_settings, port: port)
          return creds unless tls[:enabled]

          case adapter
          when :postgres
            creds[:sslmode]     = tls[:verify] == :none ? 'require' : 'verify-full'
            creds[:sslrootcert] = tls[:ca] if tls[:ca]
            creds[:sslcert]     = tls[:cert] if tls[:cert]
            creds[:sslkey]      = tls[:key] if tls[:key]
          when :mysql2
            creds[:ssl_mode] = tls[:verify] == :none ? 'required' : 'verify_identity'
            creds[:sslca]    = tls[:ca] if tls[:ca]
            creds[:sslcert]  = tls[:cert] if tls[:cert]
            creds[:sslkey]   = tls[:key] if tls[:key]
          end

          creds
        end

        def creds_builder(final_creds = {})
          final_creds.merge! Legion::Data::Settings.creds(adapter)
          final_creds.merge! Legion::Settings[:data][:creds] if Legion::Settings[:data][:creds].is_a? Hash

          port = final_creds[:port]
          merge_tls_creds(final_creds, adapter: adapter, port: port)

          return final_creds if Legion::Settings[:vault].nil?

          if Legion::Settings[:vault][:connected] && ::Vault.sys.mounts.key?(:database)
            temp_vault_creds = Legion::Crypt.read('database/creds/legion')
            final_creds[:user] = temp_vault_creds[:username]
            final_creds[:password] = temp_vault_creds[:password]
          end

          final_creds
        end

        private

        def data_tls_settings
          return {} unless defined?(Legion::Settings)

          Legion::Settings[:data][:tls] || {}
        rescue StandardError
          {}
        end

        def dev_fallback?
          data_settings = Legion::Settings[:data]
          data_settings[:dev_mode] == true && data_settings[:dev_fallback] != false
        end

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
