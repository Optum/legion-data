# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Identity::ModelHelpers.table_available?(:portable_identity_providers)

module Legion
  module Data
    module Model
      class Identity
        class Provider < Sequel::Model(:portable_identity_providers)
          include ModelHelpers

          one_to_many :identities, class: 'Legion::Data::Model::Identity::Identity', key: :provider_id
          one_to_many :capabilities,
                      class: 'Legion::Data::Model::Identity::ProviderCapability',
                      key:   :provider_id

          def self.lookup_columns
            %i[id uuid name]
          end

          def parsed_capabilities
            capabilities_dataset.select_map(:capability_key)
          end
        end

        class ProviderCapability < Sequel::Model(:portable_identity_provider_capabilities)
          many_to_one :provider, class: 'Legion::Data::Model::Identity::Provider'
        end
      end
    end
  end
end
