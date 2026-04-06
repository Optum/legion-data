# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Principal < Sequel::Model(:principals)
        one_to_many :identities, class: 'Legion::Data::Model::Identity'
        one_to_many :group_memberships, class: 'Legion::Data::Model::IdentityGroupMembership'

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
