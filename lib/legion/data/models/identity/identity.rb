# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      class Identity
        class Identity < Sequel::Model(:identities)
          include ModelHelpers

          many_to_one :principal, class: 'Legion::Data::Model::Identity::Principal'
          many_to_one :provider, class: 'Legion::Data::Model::Identity::Provider', key: :provider_id

          def self.lookup_columns
            %i[id uuid provider_identity_key]
          end
        end
      end
    end
  end
end
