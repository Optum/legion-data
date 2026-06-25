# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module RBAC
        class CrossTeamGrant < Sequel::Model(:rbac_cross_team_grants)
          include ModelHelpers

          def validate
            super
            errors.add(:source_team, 'cannot be empty') if source_team.nil? || source_team.empty?
            errors.add(:target_team, 'cannot be empty') if target_team.nil? || target_team.empty?
            errors.add(:source_team, 'cannot equal target_team') if source_team == target_team
            errors.add(:runner_pattern, 'cannot be empty') if runner_pattern.nil? || runner_pattern.empty?
            errors.add(:actions, 'cannot be empty') if actions.nil? || actions.empty?
            errors.add(:granted_by, 'cannot be empty') if granted_by.nil? || granted_by.empty?
          end
        end
      end
    end
  end
end
