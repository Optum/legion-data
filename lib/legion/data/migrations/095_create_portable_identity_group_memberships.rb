# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:portable_identity_group_memberships) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :principal_id, :portable_identity_principals, null: false, on_delete: :cascade
      foreign_key :group_id, :portable_identity_groups, null: false, on_delete: :cascade
      String :status, size: 32, null: false, default: 'active'
      String :discovered_by, size: 255, null: false
      Integer :trust_weight, null: false, default: 50
      DateTime :expires_at
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[principal_id group_id discovered_by]
      index :uuid
      index :principal_id
      index :group_id
      index :status
      index %i[principal_id status]
    end
  end
end
