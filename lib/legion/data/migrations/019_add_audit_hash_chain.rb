# frozen_string_literal: true

Sequel.migration do
  up do
    return unless table_exists?(:audit_log)

    alter_table(:audit_log) do
      add_column :record_hash, String, size: 64
      add_column :previous_hash, String, size: 64
      add_column :retention_tier, String, size: 10, default: 'hot'
      add_index :record_hash, unique: true, if_not_exists: true
      add_index :retention_tier, if_not_exists: true
    end
  end

  down do
    return unless table_exists?(:audit_log)

    alter_table(:audit_log) do
      drop_column :record_hash
      drop_column :previous_hash
      drop_column :retention_tier
    end
  end
end
