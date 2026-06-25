# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:data_archive) do
      primary_key :id
      String :source_table, null: false, size: 64, index: true
      Integer :source_id, null: false
      String :data, text: true, null: false
      Integer :tier, default: 1
      DateTime :archived_at, default: Sequel::CURRENT_TIMESTAMP
      index %i[source_table source_id]
      index :tier
    end
  end

  down do
    drop_table?(:data_archive)
  end
end
