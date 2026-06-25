# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      class Identity
        class Group < Sequel::Model(:identity_groups)
          include ModelHelpers

          one_to_many :memberships, class: 'Legion::Data::Model::Identity::GroupMembership', key: :group_id
          many_to_many :principals,
                       class:      'Legion::Data::Model::Identity::Principal',
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
end
