# frozen_string_literal: true

require_relative 'identity/model_helpers'

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class IdentityProvider < Sequel::Model(:identity_providers)
        include Identity::ModelHelpers

        one_to_many :identities, class: 'Legion::Data::Model::Identity'

        def self.lookup_columns
          %i[id uuid name]
        end

        def parsed_capabilities
          Array(capabilities)
        end
      end
    end
  end
end
