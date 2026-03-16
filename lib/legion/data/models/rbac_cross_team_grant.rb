# frozen_string_literal: true

module Legion
  module Data
    module Model
      class RbacCrossTeamGrant < Sequel::Model
        def validate
          super
          errors.add(:source_team, 'cannot be empty') if source_team.nil? || source_team.empty?
          errors.add(:target_team, 'cannot be empty') if target_team.nil? || target_team.empty?
          errors.add(:source_team, 'cannot equal target_team') if source_team == target_team
          errors.add(:runner_pattern, 'cannot be empty') if runner_pattern.nil? || runner_pattern.empty?
          errors.add(:actions, 'cannot be empty') if actions.nil? || actions.empty?
          errors.add(:granted_by, 'cannot be empty') if granted_by.nil? || granted_by.empty?
        end

        def expired?
          return false if expires_at.nil?

          expires_at < Time.now
        end

        def active?
          !expired?
        end

        def actions_list
          (actions || '').split(',').map(&:strip)
        end
      end
    end
  end
end
