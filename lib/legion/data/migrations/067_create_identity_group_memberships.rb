# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    create_table(:identity_group_memberships) do
      column :id, :uuid, default: Sequel.lit('gen_random_uuid()'), primary_key: true
      foreign_key :principal_id, :principals, type: :uuid, null: false, on_delete: :cascade
      foreign_key :group_id, :identity_groups, type: :uuid, null: false, on_delete: :cascade
      String :status, null: false, default: 'active' # active, stale, expired
      String :discovered_by, null: false # provider name that discovered this membership
      Integer :trust_weight, null: false, default: 50
      DateTime :expires_at
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[principal_id group_id discovered_by]
    end

    add_index :identity_group_memberships, :principal_id
    add_index :identity_group_memberships, :group_id
    add_index :identity_group_memberships, :status
    run <<~SQL
      CREATE INDEX idx_memberships_trust_tiebreak
        ON identity_group_memberships (principal_id, trust_weight ASC,
          CASE status WHEN 'expired' THEN 0 WHEN 'stale' THEN 1 WHEN 'active' THEN 2 END ASC)
    SQL
  end

  down do
    next unless adapter_scheme == :postgres

    drop_table?(:identity_group_memberships)
  end
end
