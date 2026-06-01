# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:llm_skill_events) do
      primary_key :id

      String   :uuid, null: false, unique: true, size: 36
      Integer  :conversation_id
      String   :request_ref
      String   :skill_name, null: false
      String   :skill_version
      String   :trigger
      String   :status, null: false, default: 'completed'
      Integer  :duration_ms, default: 0
      String   :identity_canonical_name
      Integer  :identity_principal_id
      Integer  :identity_id
      Integer  :schema_version, null: false, default: 15
      DateTime :recorded_at, null: false
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index [:conversation_id]
      index [:request_ref]
      index [:skill_name]
      index [:identity_canonical_name]
      index [:recorded_at]
      index [:inserted_at]
    end
  end

  down do
    drop_table :llm_skill_events
  end
end
