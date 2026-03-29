# frozen_string_literal: true

module Legion
  module Data
    module Model
      class AuditRecord < Sequel::Model(:audit_records)
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
          Legion::Logging.warn "AuditRecord#parsed_metadata failed: #{e.message}" if defined?(Legion::Logging)
          {}
        end
      end
    end
  end
end
