# frozen_string_literal: true

Sequel.migration do
  up do
    next if table_exists?(:absorber_patterns)

    create_table(:absorber_patterns) do
      primary_key :id
      foreign_key :function_id, :functions, null: false, on_delete: :cascade, index: true
      String :pattern_type, size: 32, null: false, default: 'url'
      String :pattern, size: 1024, null: false
      Integer :priority, null: false, default: 0
      TrueClass :active, null: false, default: true
      String :tenant_id, size: 64, null: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: true

      index :pattern_type, name: :idx_absorber_patterns_pattern_type
      index :active, name: :idx_absorber_patterns_active
      index :tenant_id, name: :idx_absorber_patterns_tenant_id
      index %i[pattern_type active], name: :idx_absorber_patterns_type_active
    end
  end

  down do
    drop_table?(:absorber_patterns)
  end
end
