# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:portable_identity_principals) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      String :canonical_name, size: 255, null: false
      String :kind, size: 64, null: false
      String :employee_key, size: 255
      String :display_name, size: 255
      TrueClass :active, null: false, default: true
      DateTime :last_seen_at
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[canonical_name kind]
      index :uuid
      index :canonical_name
      index :kind
      index :employee_key
      index :active
    end
  end
end
