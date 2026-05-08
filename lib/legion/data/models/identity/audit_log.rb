# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      class Identity
        class AuditLog < Sequel::Model(:identity_audit_log)
          include ModelHelpers

          many_to_one :principal, class: 'Legion::Data::Model::Identity::Principal'
          many_to_one :identity, class: 'Legion::Data::Model::Identity::Identity'
        end
      end
    end
  end
end
