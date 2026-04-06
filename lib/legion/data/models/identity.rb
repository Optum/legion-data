# frozen_string_literal: true

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class Identity < Sequel::Model(:identities)
        many_to_one :principal, class: 'Legion::Data::Model::Principal'
        many_to_one :provider, class: 'Legion::Data::Model::IdentityProvider', key: :provider_id

        if defined?(Legion::Data::Encryption::SequelPlugin)
          plugin Legion::Data::Encryption::SequelPlugin
          encrypted_column :profile
        end
      end
    end
  end
end
