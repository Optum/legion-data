# frozen_string_literal: true

Sequel.migration do
  up do
    next unless [:postgres].include?(adapter_scheme)
    next if table_exists?(:archive_manifest)

    create_table(:archive_manifest) do
      primary_key :id
      String :batch_id, null: false, unique: true
      String :source_table, null: false
      Integer :row_count, null: false
      String :checksum, null: false
      String :storage_path, null: false
      DateTime :archived_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      column :metadata, :jsonb

      index :source_table
      index :archived_at
    end
  end

  down do
    next unless [:postgres].include?(adapter_scheme)

    drop_table(:archive_manifest) if table_exists?(:archive_manifest)
  end
end
