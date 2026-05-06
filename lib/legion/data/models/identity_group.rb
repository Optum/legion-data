# frozen_string_literal: true

require_relative 'identity/model_helpers'

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class IdentityGroup < Sequel::Model(:identity_groups)
        include Identity::ModelHelpers

        one_to_many :memberships, class: 'Legion::Data::Model::IdentityGroupMembership', key: :group_id
        many_to_many :principals,
                     class:      'Legion::Data::Model::Principal',
                     join_table: :identity_group_memberships,
                     left_key:   :group_id,
                     right_key:  :principal_id

        def self.lookup_columns
          %i[id uuid name]
        end
      end
    end
  end
end
