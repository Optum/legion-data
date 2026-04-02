# frozen_string_literal: true

require 'legion/logging/helper'

module Legion
  module Data
    module Model
      class AuditLog < Sequel::Model(:audit_log)
        include Legion::Logging::Helper

        VALID_EVENT_TYPES = %w[runner_execution lifecycle_transition].freeze
        VALID_STATUSES    = %w[success failure denied].freeze

        def validate
          super
          errors.add(:event_type, 'invalid') unless VALID_EVENT_TYPES.include?(event_type)
          errors.add(:status, 'invalid')     unless VALID_STATUSES.include?(status)
        end

        def parsed_detail
          return nil unless detail

          Legion::JSON.load(detail)
        rescue StandardError => e
          handle_exception(e, level: :warn, handled: true, operation: :parsed_detail, id: self[:id])
          nil
        end

        def before_update
          raise 'audit_log records are immutable and cannot be updated'
        end

        def before_destroy
          raise 'audit_log records are immutable and cannot be deleted'
        end
      end
    end
  end
end
