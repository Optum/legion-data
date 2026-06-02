# frozen_string_literal: true

# The Great Convergence (part 1 of 2): add entity_type column to audit_records on all adapters.
# Migration 068 added this column on PostgreSQL only.
# Production is already at 117+, so this migration only runs on SQLite/MySQL
# deployments that missed it due to the postgres-only guard in migration 068.

Sequel.migration do
  up do
    next unless table_exists?(:audit_records)

    existing = schema(:audit_records).map(&:first)
    next if existing.include?(:entity_type)

    alter_table(:audit_records) do
      add_column :entity_type, String, size: 100, null: true
    end

    add_index :audit_records, :entity_type, name: :idx_audit_records_entity_type, if_not_exists: true
  end

  down do
    next unless table_exists?(:audit_records)

    alter_table(:audit_records) do
      drop_column :entity_type if schema(:audit_records).any? { |col, _| col == :entity_type }
    end
  end
end
