# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:apollo_entries)

    existing_columns = schema(:apollo_entries).map(&:first)

    alter_table(:apollo_entries) do
      add_column :parent_knowledge_id, :uuid, null: true unless existing_columns.include?(:parent_knowledge_id)
      add_column :is_latest, :boolean, null: false, default: true unless existing_columns.include?(:is_latest)
      add_column :supersession_type, String, size: 20, null: true unless existing_columns.include?(:supersession_type)
      add_column :expires_at, :timestamptz, null: true unless existing_columns.include?(:expires_at)
      add_column :forget_reason, String, size: 255, null: true unless existing_columns.include?(:forget_reason)
      add_column :is_inference, :boolean, null: false, default: false unless existing_columns.include?(:is_inference)
    end

    add_index :apollo_entries, :parent_knowledge_id, name: :idx_apollo_parent_knowledge, if_not_exists: true
    add_index :apollo_entries, %i[parent_knowledge_id is_latest],
              name:          :idx_apollo_version_chain,
              where:         Sequel.lit('is_latest = true'),
              if_not_exists: true
    add_index :apollo_entries, :expires_at,
              name:          :idx_apollo_expiry,
              where:         Sequel.lit("expires_at IS NOT NULL AND status != 'archived'"),
              if_not_exists: true
    add_index :apollo_entries, :is_inference,
              name:          :idx_apollo_inference,
              where:         Sequel.lit('is_inference = true'),
              if_not_exists: true
  end

  down do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:apollo_entries)

    existing_columns = schema(:apollo_entries).map(&:first)

    alter_table(:apollo_entries) do
      drop_column :parent_knowledge_id if existing_columns.include?(:parent_knowledge_id)
      drop_column :is_latest if existing_columns.include?(:is_latest)
      drop_column :supersession_type if existing_columns.include?(:supersession_type)
      drop_column :expires_at if existing_columns.include?(:expires_at)
      drop_column :forget_reason if existing_columns.include?(:forget_reason)
      drop_column :is_inference if existing_columns.include?(:is_inference)
    end
  end
end
