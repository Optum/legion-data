# frozen_string_literal: true

require 'legion/logging/helper'

module Legion
  module Data
    module Model
      class AuditRecord < Sequel::Model(:audit_records)
        include Legion::Logging::Helper

        # Enforce append-only semantics at the application layer.
        # PostgreSQL enforces this at the DB layer via rules (migration 058);
        # the application guard covers SQLite and MySQL.

        def before_update
          raise 'audit_records are immutable and cannot be updated'
        end

        def before_destroy
          raise 'audit_records are immutable and cannot be deleted'
        end

        def parsed_metadata
          return {} unless metadata

          Legion::JSON.load(metadata)
        rescue StandardError => e
          handle_exception(e, level: :warn, handled: true, operation: :parsed_metadata, id: self[:id])
          {}
        end
      end
    end
  end
end
