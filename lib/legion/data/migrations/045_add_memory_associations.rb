# frozen_string_literal: true

Sequel.migration do
  up do
    next if table_exists?(:memory_associations)

    create_table(:memory_associations) do
      primary_key :id
      String :trace_id_a, size: 36, null: false
      String :trace_id_b, size: 36, null: false
      Integer :coactivation_count, default: 1, null: false
      TrueClass :linked, default: false, null: false
      String :tenant_id, size: 64
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      unique %i[trace_id_a trace_id_b]
      index :trace_id_a
      index :trace_id_b
      index :tenant_id
    end
  end

  down do
    drop_table?(:memory_associations)
  end
end
