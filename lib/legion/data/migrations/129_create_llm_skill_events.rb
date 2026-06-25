# frozen_string_literal: true

Sequel.migration do
  up do
    next if table_exists?(:llm_skill_events)

    create_table(:llm_skill_events) do
      primary_key :id

      String   :uuid, null: false, unique: true, size: 36
      Integer  :conversation_id, index: true
      String   :request_ref, index: true
      String   :skill_name, null: false, index: true
      String   :skill_version
      String   :trigger
      String   :status, null: false, default: 'completed'
      Integer  :duration_ms, default: 0
      String   :identity_canonical_name, index: true
      Integer  :identity_principal_id
      Integer  :identity_id
      Integer  :schema_version, null: false, default: 15
      DateTime :recorded_at, null: false, index: true
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP, index: true
    end
  end

  down do
    drop_table(:llm_skill_events) if table_exists?(:llm_skill_events)
  end
end
