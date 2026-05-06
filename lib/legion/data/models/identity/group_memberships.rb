# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Identity::ModelHelpers.table_available?(:portable_identity_group_memberships)

module Legion
  module Data
    module Model
      class Identity
        class GroupMembership < Sequel::Model(:portable_identity_group_memberships)
          include ModelHelpers

          many_to_one :principal, class: 'Legion::Data::Model::Identity::Principal'
          many_to_one :group, class: 'Legion::Data::Model::Identity::Group'

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
end
