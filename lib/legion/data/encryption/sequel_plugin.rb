# frozen_string_literal: true

require 'legion/logging/helper'
require_relative 'cipher'
require_relative 'key_provider'

module Legion
  module Data
    module Encryption
      module SequelPlugin
        extend Legion::Logging::Helper

        class << self
          def aad_for(table_name:, primary_key:, column:)
            "#{table_name}:#{primary_key || 0}:#{column}"
          end

          def decrypt_value(blob:, key:, table_name:, primary_key:, column:)
            errors = []

            aad_candidates(primary_key).each do |aad_primary_key|
              aad = aad_for(table_name: table_name, primary_key: aad_primary_key, column: column)
              return Legion::Data::Encryption::Cipher.decrypt(blob, key: key, aad: aad)
            rescue OpenSSL::Cipher::CipherError, ArgumentError => e
              errors << e
            end

            raise errors.last if errors.any?
          end

          private

          def aad_candidates(primary_key)
            [primary_key, 0].compact.uniq
          end
        end

        module ClassMethods
          def encrypted_columns
            @encrypted_columns ||= {}
          end

          def encrypted_column(name, key_scope: :default)
            col_scope = key_scope
            encrypted_columns[name] = { key_scope: col_scope }

            define_method(name) do
              raw = super()
              return nil if raw.nil?

              begin
                decrypt_encrypted_column(name, raw, key_scope: col_scope)
              rescue StandardError => e
                Legion::Data::Encryption::SequelPlugin.handle_exception(
                  e,
                  level:       :warn,
                  handled:     false,
                  operation:   :decrypt_column,
                  table:       self.class.table_name,
                  primary_key: pk,
                  column:      name
                )
                raise
              end
            end

            define_method(:"#{name}=") do |value|
              if value.nil?
                clear_pending_encrypted_column(name)
                super(nil)
              else
                begin
                  remember_pending_encrypted_column(name, value, key_scope: col_scope) if new?
                  super(encrypt_encrypted_column(name, value, key_scope: col_scope, primary_key: pk || 0))
                rescue StandardError => e
                  Legion::Data::Encryption::SequelPlugin.handle_exception(
                    e,
                    level:       :error,
                    handled:     false,
                    operation:   :encrypt_column,
                    table:       self.class.table_name,
                    primary_key: pk,
                    column:      name
                  )
                  raise
                end
              end
            end
          end

          def encryption_key_provider
            @encryption_key_provider ||= KeyProvider.new
          end
        end

        module InstanceMethods
          def after_create
            super
            reencrypt_pending_encrypted_columns
          end

          private

          def decrypt_encrypted_column(column, raw, key_scope:)
            provider = self.class.encryption_key_provider
            tenant = key_scope == :tenant ? self[:tenant_id] : nil
            key = provider.key_for(tenant_id: tenant)

            Legion::Data::Encryption::SequelPlugin.decrypt_value(
              blob:        raw.b,
              key:         key,
              table_name:  self.class.table_name,
              primary_key: pk,
              column:      column
            )
          end

          def encrypt_encrypted_column(column, value, key_scope:, primary_key:)
            provider = self.class.encryption_key_provider
            tenant = key_scope == :tenant ? self[:tenant_id] : nil
            key = provider.key_for(tenant_id: tenant)
            aad = Legion::Data::Encryption::SequelPlugin.aad_for(
              table_name:  self.class.table_name,
              primary_key: primary_key,
              column:      column
            )
            encrypted = Legion::Data::Encryption::Cipher.encrypt(value.to_s, key: key, aad: aad)
            Sequel.blob(encrypted)
          end

          def pending_encrypted_columns
            @pending_encrypted_columns ||= {}
          end

          def remember_pending_encrypted_column(column, value, key_scope:)
            pending_encrypted_columns[column] = { key_scope: key_scope, value: value.to_s }
          end

          def clear_pending_encrypted_column(column)
            pending_encrypted_columns.delete(column) if defined?(@pending_encrypted_columns)
          end

          def reencrypt_pending_encrypted_columns
            return if pending_encrypted_columns.empty?

            encrypted_values = pending_encrypted_columns.each_with_object({}) do |(column, config), updates|
              updates[column] = encrypt_encrypted_column(
                column,
                config[:value],
                key_scope:   config[:key_scope],
                primary_key: pk
              )
            end

            self.class.where(pk_hash).update(encrypted_values)
            encrypted_values.each { |column, encrypted| values[column] = encrypted }
            pending_encrypted_columns.clear
          rescue StandardError => e
            Legion::Data::Encryption::SequelPlugin.handle_exception(
              e,
              level:       :error,
              handled:     false,
              operation:   :reencrypt_pending_columns,
              table:       self.class.table_name,
              primary_key: pk
            )
            raise
          end
        end
      end
    end
  end
end
