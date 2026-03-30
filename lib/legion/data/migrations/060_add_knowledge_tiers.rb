# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:apollo_entries)

    existing_columns = schema(:apollo_entries).map(&:first)

    alter_table(:apollo_entries) do
      add_column :summary_l0, String, size: 500, null: true unless existing_columns.include?(:summary_l0)
      add_column :summary_l1, :text, null: true unless existing_columns.include?(:summary_l1)
      add_column :knowledge_tier, String, size: 4, null: false, default: 'L2' unless existing_columns.include?(:knowledge_tier)
      add_column :parent_entry_id, :uuid, null: true unless existing_columns.include?(:parent_entry_id)
      add_column :l0_generated_at, :timestamptz, null: true unless existing_columns.include?(:l0_generated_at)
      add_column :l1_generated_at, :timestamptz, null: true unless existing_columns.include?(:l1_generated_at)
    end

    add_index :apollo_entries, :knowledge_tier, name: :idx_apollo_knowledge_tier, if_not_exists: true
    add_index :apollo_entries, :parent_entry_id, name: :idx_apollo_parent_entry, if_not_exists: true
  end

  down do
    next unless adapter_scheme == :postgres
    next unless table_exists?(:apollo_entries)

    existing_columns = schema(:apollo_entries).map(&:first)

    alter_table(:apollo_entries) do
      drop_column :summary_l0 if existing_columns.include?(:summary_l0)
      drop_column :summary_l1 if existing_columns.include?(:summary_l1)
      drop_column :knowledge_tier if existing_columns.include?(:knowledge_tier)
      drop_column :parent_entry_id if existing_columns.include?(:parent_entry_id)
      drop_column :l0_generated_at if existing_columns.include?(:l0_generated_at)
      drop_column :l1_generated_at if existing_columns.include?(:l1_generated_at)
    end
  end
end
