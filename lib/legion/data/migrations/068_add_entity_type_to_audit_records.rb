# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:audit_records)

    alter_table(:audit_records) do
      add_column :entity_type, String, size: 100, null: true
    end

    add_index :audit_records, :entity_type, name: :idx_audit_records_entity_type
  end

  down do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:audit_records)

    alter_table(:audit_records) do
      drop_column :entity_type
    end
  end
end
