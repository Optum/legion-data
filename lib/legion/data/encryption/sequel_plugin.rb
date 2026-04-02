# frozen_string_literal: true

require 'legion/logging/helper'
require_relative 'cipher'
require_relative 'key_provider'

module Legion
  module Data
    module Encryption
      module SequelPlugin
        extend Legion::Logging::Helper

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

              provider = self.class.encryption_key_provider
              tenant = col_scope == :tenant ? self[:tenant_id] : nil
              key = provider.key_for(tenant_id: tenant)
              aad = "#{self.class.table_name}:#{pk}:#{name}"
              begin
                Legion::Data::Encryption::Cipher.decrypt(raw.b, key: key, aad: aad)
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
                super(nil)
              else
                begin
                  provider = self.class.encryption_key_provider
                  tenant = col_scope == :tenant ? self[:tenant_id] : nil
                  key = provider.key_for(tenant_id: tenant)
                  aad = "#{self.class.table_name}:#{pk || 0}:#{name}"
                  encrypted = Legion::Data::Encryption::Cipher.encrypt(value.to_s, key: key, aad: aad)
                  super(Sequel.blob(encrypted))
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
        end
      end
    end
  end
end
