# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module RBAC
        class RoleAssignment < Sequel::Model(:rbac_role_assignments)
          include ModelHelpers

          VALID_PRINCIPAL_TYPES = %w[worker human].freeze

          def validate
            super
            errors.add(:principal_type, 'must be worker or human') unless VALID_PRINCIPAL_TYPES.include?(principal_type)
            errors.add(:principal_id, 'cannot be empty') if principal_id.nil? || principal_id.empty?
            errors.add(:role, 'cannot be empty') if role.nil? || role.empty?
            errors.add(:granted_by, 'cannot be empty') if granted_by.nil? || granted_by.empty?
          end
        end
      end
    end
  end
end
