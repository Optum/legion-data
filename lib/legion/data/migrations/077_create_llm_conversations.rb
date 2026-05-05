# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_conversations) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      Integer :principal_id
      Integer :identity_id
      String :title, size: 255
      String :status, size: 32, null: false, default: 'active'
      String :system_prompt_key, size: 255
      String :system_prompt_hash, size: 128
      String :classification_level, size: 64
      TrueClass :contains_phi, null: false, default: false
      TrueClass :contains_pii, null: false, default: false
      String :retention_policy, size: 64, null: false, default: 'default'
      DateTime :expires_at
      DateTime :recorded_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index :principal_id
      index :identity_id
      index :status
      index :retention_policy
      index :expires_at
    end
  end
end
