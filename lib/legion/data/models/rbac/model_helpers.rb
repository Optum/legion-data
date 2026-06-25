# frozen_string_literal: true

module Legion
  module Data
    module Model
      module RBAC
        module ModelHelpers
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
end
