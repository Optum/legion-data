# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Identity::ModelHelpers.table_available?(:portable_identity_principals)

module Legion
  module Data
    module Model
      class Identity
        class Principal < Sequel::Model(:portable_identity_principals)
          include ModelHelpers

          one_to_many :identities, class: 'Legion::Data::Model::Identity::Identity'
          one_to_many :group_memberships, class: 'Legion::Data::Model::Identity::GroupMembership'
          many_to_many :groups,
                       class:      'Legion::Data::Model::Identity::Group',
                       join_table: :portable_identity_group_memberships,
                       left_key:   :principal_id,
                       right_key:  :group_id

          def self.lookup_columns
            %i[id uuid canonical_name employee_key]
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
end
