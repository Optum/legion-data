# frozen_string_literal: true

Sequel.migration do
  up do
    next if table_exists?(:audit_records)

    create_table(:audit_records) do
      primary_key :id
      String   :chain_id,     size: 255, null: false
      String   :content_type, size: 100, null: false
      column   :metadata,     :text,     null: true
      String   :content_hash, size: 64,  null: false
      String   :parent_hash,  size: 64,  null: false
      String   :chain_hash,   size: 64,  null: false, unique: true
      String   :signature,    size: 512, null: true
      DateTime :created_at,   null: false

      index :chain_id,     name: :idx_audit_records_chain_id
      index :content_type, name: :idx_audit_records_content_type
      index :created_at,   name: :idx_audit_records_created_at
      index %i[chain_id created_at], name: :idx_audit_records_chain_time
    end

    if database_type == :postgres
      run <<~SQL
        CREATE RULE no_update_audit_records AS ON UPDATE TO audit_records DO INSTEAD NOTHING;
        CREATE RULE no_delete_audit_records AS ON DELETE TO audit_records DO INSTEAD NOTHING;
      SQL
    end
  end

  down do
    next unless table_exists?(:audit_records)

    if database_type == :postgres
      run 'DROP RULE IF EXISTS no_update_audit_records ON audit_records;'
      run 'DROP RULE IF EXISTS no_delete_audit_records ON audit_records;'
    end

    drop_table :audit_records
  end
end
