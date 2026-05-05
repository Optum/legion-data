# frozen_string_literal: true

require_relative 'identity/model_helpers'

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class Identity < Sequel::Model(:identities)
        include ModelHelpers

        many_to_one :principal, class: 'Legion::Data::Model::Principal'
        many_to_one :provider, class: 'Legion::Data::Model::IdentityProvider', key: :provider_id

        def self.lookup_columns
          %i[id uuid provider_identity_key provider_identity]
        end

        if defined?(Legion::Data::Encryption::SequelPlugin)
          plugin Legion::Data::Encryption::SequelPlugin
          encrypted_column :profile
        end
      end
    end
  end
end
