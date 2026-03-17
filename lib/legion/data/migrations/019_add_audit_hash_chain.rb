# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:audit_log)

    cols = schema(:audit_log).map(&:first)

    alter_table(:audit_log) do
      add_column :record_hash, String, size: 64 unless cols.include?(:record_hash)
      add_column :previous_hash, String, size: 64 unless cols.include?(:previous_hash)
      add_column :retention_tier, String, size: 10, default: 'hot' unless cols.include?(:retention_tier)
      add_index :record_hash, unique: true, if_not_exists: true
      add_index :retention_tier, if_not_exists: true
    end
  end

  down do
    return unless table_exists?(:audit_log)

    cols = schema(:audit_log).map(&:first)

    alter_table(:audit_log) do
      drop_column :record_hash if cols.include?(:record_hash)
      drop_column :previous_hash if cols.include?(:previous_hash)
      drop_column :retention_tier if cols.include?(:retention_tier)
    end
  end
end
