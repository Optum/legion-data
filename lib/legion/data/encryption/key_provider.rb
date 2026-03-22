# frozen_string_literal: true

require 'openssl'

module Legion
  module Data
    module Encryption
      class KeyProvider
        def initialize(mode: :auto)
          @mode = mode
          @key_cache = {}
        end

        def key_for(tenant_id: nil)
          cache_key = tenant_id || '__default__'
          @key_cache[cache_key] ||= derive_key(tenant_id)
        end

        def clear_cache!
          @key_cache.clear
        end

        private

        def derive_key(tenant_id)
          if tenant_id && crypt_available?
            Legion::Logging.debug "Deriving Vault key for tenant #{tenant_id}" if defined?(Legion::Logging)
            Legion::Crypt::PartitionKeys.derive(tenant_id: tenant_id)
          elsif crypt_available?
            Legion::Crypt.default_encryption_key
          else
            Legion::Logging.warn 'Legion::Crypt unavailable, falling back to dev encryption key' if defined?(Legion::Logging)
            local_key
          end
        end

        def crypt_available?
          defined?(Legion::Crypt::PartitionKeys)
        end

        def local_key
          OpenSSL::Digest.digest('SHA256', 'legion-dev-encryption-key')
        end
      end
    end
  end
end
