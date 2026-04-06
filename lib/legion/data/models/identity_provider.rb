# frozen_string_literal: true

module Legion
  module Data
    module Model
      class IdentityProvider < Sequel::Model(:identity_providers)
        one_to_many :identities, class: 'Legion::Data::Model::Identity'

        def parsed_capabilities
          Array(capabilities)
        end
      end
    end
  end
end
