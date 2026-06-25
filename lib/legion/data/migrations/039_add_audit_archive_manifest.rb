# frozen_string_literal: true

Sequel.migration do
  up do
    unless table_exists?(:audit_archive_manifests)
      create_table(:audit_archive_manifests) do
        primary_key :id
        String   :tier,        null: false, size: 10   # hot, warm, cold
        String   :storage_url, null: false, size: 2000
        DateTime :start_date,  null: false
        DateTime :end_date,    null: false
        Integer  :entry_count, null: false
        String   :checksum,    null: false, size: 64   # SHA-256 hex
        String   :first_hash,  null: false, size: 64   # record_hash of first entry
        String   :last_hash,   null: false, size: 64   # record_hash of last entry
        DateTime :archived_at, null: false, default: Sequel::CURRENT_TIMESTAMP

        index :tier
        index :archived_at
        index %i[start_date end_date]
      end
    end
  end

  down do
    drop_table(:audit_archive_manifests) if table_exists?(:audit_archive_manifests)
  end
end
