# frozen_string_literal: true

require_relative 'identity/model_helpers'

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class Principal < Sequel::Model(:principals)
        include Identity::ModelHelpers

        one_to_many :identities, class: 'Legion::Data::Model::Identity'
        one_to_many :group_memberships, class: 'Legion::Data::Model::IdentityGroupMembership'
        many_to_many :groups,
                     class:      'Legion::Data::Model::IdentityGroup',
                     join_table: :identity_group_memberships,
                     left_key:   :principal_id,
                     right_key:  :group_id

        def self.lookup_columns
          %i[id uuid canonical_name employee_key employee_id]
        end

        def active_groups
          group_memberships_dataset
            .where(status: 'active')
            .eager(:group)
            .all
            .map(&:group)
        end
      end
    end
  end
end
