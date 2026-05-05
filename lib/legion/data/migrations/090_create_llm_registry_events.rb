# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_registry_events) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      String :provider, size: 128
      String :model_key, size: 255
      String :event_type, size: 128, null: false
      String :status, size: 64, null: false
      String :reason, text: true
      DateTime :recorded_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :uuid
      index %i[provider model_key]
      index :event_type
      index :status
      index :recorded_at
    end
  end
end
