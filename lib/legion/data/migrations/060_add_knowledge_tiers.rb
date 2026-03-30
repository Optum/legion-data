# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      add_column :summary_l0, String, size: 500, null: true
      add_column :summary_l1, :text, null: true
      add_column :knowledge_tier, String, size: 4, null: false, default: 'L2'
      add_column :parent_entry_id, :uuid, null: true
      add_column :l0_generated_at, :timestamptz, null: true
      add_column :l1_generated_at, :timestamptz, null: true
    end

    add_index :apollo_entries, :knowledge_tier, name: :idx_apollo_knowledge_tier
    add_index :apollo_entries, :parent_entry_id, name: :idx_apollo_parent_entry
  end

  down do
    next unless adapter_scheme == :postgres

    alter_table(:apollo_entries) do
      drop_column :summary_l0
      drop_column :summary_l1
      drop_column :knowledge_tier
      drop_column :parent_entry_id
      drop_column :l0_generated_at
      drop_column :l1_generated_at
    end
  end
end
