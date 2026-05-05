# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:llm_tool_call_attempts) do
      primary_key :id
      String :uuid, size: 36, null: false, unique: true
      foreign_key :tool_call_id, :llm_tool_calls, null: false, on_delete: :cascade
      Integer :attempt_no, null: false
      String :runner_ref, size: 128
      String :status, size: 64, null: false
      String :error_category, size: 128
      String :error_code, size: 128
      String :error_message, text: true
      Integer :duration_ms, null: false, default: 0
      String :arguments_ref, size: 255
      String :result_ref, size: 255
      DateTime :started_at
      DateTime :ended_at
      DateTime :inserted_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      unique %i[tool_call_id attempt_no]
      index :uuid
      index :tool_call_id
      index :runner_ref
      index :status
      index :started_at
    end
  end
end
