# frozen_string_literal: true

require 'openssl'

module Legion
  module Data
    module Encryption
      module Cipher
        VERSION_BYTE = "\x01".b.freeze
        IV_LENGTH = 12
        TAG_LENGTH = 16

        class << self
          def encrypt(plaintext, key:, aad: '')
            cipher = OpenSSL::Cipher.new('aes-256-gcm').encrypt
            iv = OpenSSL::Random.random_bytes(IV_LENGTH)
            cipher.key = key
            cipher.iv = iv
            cipher.auth_data = aad

            ciphertext = cipher.update(plaintext.to_s) + cipher.final
            tag = cipher.auth_tag(TAG_LENGTH)

            VERSION_BYTE + iv + ciphertext + tag
          end

          def decrypt(blob, key:, aad: '')
            raise ArgumentError, 'data too short' if blob.bytesize < 1 + IV_LENGTH + TAG_LENGTH

            version = blob.byteslice(0, 1)
            raise ArgumentError, "unsupported version: #{version.unpack1('C')}" unless version == VERSION_BYTE

            iv = blob.byteslice(1, IV_LENGTH)
            tag = blob.byteslice(-TAG_LENGTH, TAG_LENGTH)
            ciphertext = blob.byteslice(1 + IV_LENGTH, blob.bytesize - 1 - IV_LENGTH - TAG_LENGTH)

            cipher = OpenSSL::Cipher.new('aes-256-gcm').decrypt
            cipher.key = key
            cipher.iv = iv
            cipher.auth_tag = tag
            cipher.auth_data = aad

            cipher.update(ciphertext) + cipher.final
          end
        end
      end
    end
  end
end
