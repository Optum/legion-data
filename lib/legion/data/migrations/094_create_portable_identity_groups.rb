# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:portable_identity_groups) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      String :name, size: 255, null: false, unique: true
      String :source, size: 64, null: false, default: 'ldap'
      String :description, text: true
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :name
      index :source
      index :active
    end
  end
end
