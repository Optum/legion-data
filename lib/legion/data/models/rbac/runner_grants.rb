# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module RBAC
        class RunnerGrant < Sequel::Model(:rbac_runner_grants)
          include ModelHelpers

          def validate
            super
            errors.add(:team, 'cannot be empty') if team.nil? || team.empty?
            errors.add(:runner_pattern, 'cannot be empty') if runner_pattern.nil? || runner_pattern.empty?
            errors.add(:actions, 'cannot be empty') if actions.nil? || actions.empty?
            errors.add(:granted_by, 'cannot be empty') if granted_by.nil? || granted_by.empty?
          end
        end
      end
    end
  end
end
