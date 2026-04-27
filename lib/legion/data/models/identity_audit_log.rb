# frozen_string_literal: true

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class IdentityAuditLog < Sequel::Model(:identity_audit_log)
        many_to_one :principal, class: 'Legion::Data::Model::Principal'
        many_to_one :identity, class: 'Legion::Data::Model::Identity'
      end
    end
  end
end
