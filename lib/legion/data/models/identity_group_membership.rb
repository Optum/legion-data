# frozen_string_literal: true

module Legion
  module Data
    module Model
      class IdentityGroupMembership < Sequel::Model(:identity_group_memberships)
        many_to_one :principal, class: 'Legion::Data::Model::Principal'
        many_to_one :group, class: 'Legion::Data::Model::IdentityGroup', key: :group_id

        def expired?
          status == 'expired' || (expires_at && Time.now >= expires_at)
        end

        def stale?
          status == 'stale'
        end
      end
    end
  end
end
