# frozen_string_literal: true

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class IdentityGroup < Sequel::Model(:identity_groups)
        one_to_many :memberships, class: 'Legion::Data::Model::IdentityGroupMembership', key: :group_id
      end
    end
  end
end
