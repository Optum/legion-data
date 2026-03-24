# frozen_string_literal: true

require 'sequel'

module Legion
  module Data
    module Connection
      ADAPTERS = %i[sqlite mysql2 postgres].freeze

      # Wraps a tagged Legion::Logging::Logger for Sequel's logger interface.
      # Prefixes warn-level messages with [slow-query] since Sequel uses warn
      # for queries exceeding log_warn_duration.
      class SlowQueryLogger
        def initialize(tagged_logger)
          @tagged = tagged_logger
        end

        def warn(message)
          @tagged.warn("[slow-query] #{message}")
        end

        def info(message)
          @tagged.info(message)
        end

        def debug(message)
          @tagged.debug(message)
        end

        def error(message)
          @tagged.error(message)
        end
      end

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
          if defined?(Legion::Logging)
            if adapter == :sqlite
              Legion::Logging.info "Connected to SQLite at #{sqlite_path}"
            else
              creds = Legion::Data::Settings.creds(adapter)
              user = creds[:user] || creds[:username] || 'unknown'
              host = creds[:host] || '127.0.0.1'
              port = creds[:port]
              db   = creds[:database] || creds[:db]
              Legion::Logging.info "Connected to #{adapter}://#{user}@#{host}:#{port}/#{db}"
            end
          end
          configure_logging
          connect_with_replicas
        end

        def shutdown
          @sequel&.disconnect
          Legion::Settings[:data][:connected] = false
          Legion::Logging.info 'Legion::Data connection closed' if defined?(Legion::Logging)
        end

        def connect_with_replicas
          return unless adapter == :postgres

          replica_url  = Legion::Settings[:data][:read_replica_url]
          replica_list = Array(Legion::Settings[:data][:replicas]).dup

          replica_list.prepend(replica_url) if replica_url && !replica_url.empty?
          replica_list.uniq!
          replica_list.compact!

          return if replica_list.empty?

          @sequel.extension(:server_block)

          replica_list.each_with_index do |url, idx|
            @sequel.add_servers("read_#{idx}": url)
          end

          @replica_servers = replica_list.each_with_index.map { |_, idx| :"read_#{idx}" }
          Legion::Logging.debug "Registered #{@replica_servers.size} read replica(s)" if defined?(Legion::Logging)
        end

        def read_server
          return :default if @replica_servers.nil? || @replica_servers.empty?

          :read_0
        end

        def replica_servers
          @replica_servers || []
        end

        def merge_tls_creds(creds, adapter:, port:)
          return creds if adapter == :sqlite
          return creds unless defined?(Legion::Crypt::TLS)

          tls_settings = data_tls_settings
          return creds unless tls_settings[:enabled] == true

          tls = Legion::Crypt::TLS.resolve(tls_settings, port: port)
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
        rescue StandardError => e
          Legion::Logging.debug("Connection#data_tls_settings failed: #{e.message}") if defined?(Legion::Logging)
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

          @sequel.logger = build_data_logger
          @sequel.sql_log_level = Legion::Settings[:data][:connection][:sql_log_level]
          @sequel.log_warn_duration = Legion::Settings[:data][:connection][:log_warn_duration]
        end

        def build_data_logger
          tagged = Legion::Logging::Logger.new(lex: 'data')
          SlowQueryLogger.new(tagged)
        end
      end
    end
  end
end
