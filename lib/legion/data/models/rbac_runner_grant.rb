# frozen_string_literal: true

module Legion
  module Data
    module Model
      class RbacRunnerGrant < Sequel::Model
        def validate
          super
          errors.add(:team, 'cannot be empty') if team.nil? || team.empty?
          errors.add(:runner_pattern, 'cannot be empty') if runner_pattern.nil? || runner_pattern.empty?
          errors.add(:actions, 'cannot be empty') if actions.nil? || actions.empty?
          errors.add(:granted_by, 'cannot be empty') if granted_by.nil? || granted_by.empty?
        end

        def actions_list
          (actions || '').split(',').map(&:strip)
        end
      end
    end
  end
end
