# frozen_string_literal: true

module Legion
  module Data
    module Model
      class RbacRoleAssignment < Sequel::Model
        VALID_PRINCIPAL_TYPES = %w[worker human].freeze

        def validate
          super
          errors.add(:principal_type, 'must be worker or human') unless VALID_PRINCIPAL_TYPES.include?(principal_type)
          errors.add(:principal_id, 'cannot be empty') if principal_id.nil? || principal_id.empty?
          errors.add(:role, 'cannot be empty') if role.nil? || role.empty?
          errors.add(:granted_by, 'cannot be empty') if granted_by.nil? || granted_by.empty?
        end

        def expired?
          return false if expires_at.nil?

          expires_at < Time.now
        end

        def active?
          !expired?
        end
      end
    end
  end
end
