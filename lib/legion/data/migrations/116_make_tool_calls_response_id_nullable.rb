# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_tool_calls) do
      set_column_allow_null :message_inference_response_id
    end

    # SQLite's set_column_allow_null recreates the table internally, which
    # drops partial indexes invisible to Sequel's indexes() method. Restore
    # the partial index from migration 109 (no-op on PG where it survives).
    alter_table(:llm_tool_calls) do
      add_index :identity_principal_id, name:          :idx_tool_calls_identity_principal_id,
                                        where:         Sequel.negate(identity_principal_id: nil),
                                        ignore_errors: true
    end
  end

  down do
    alter_table(:llm_tool_calls) do
      set_column_not_null :message_inference_response_id
    end

    alter_table(:llm_tool_calls) do
      add_index :identity_principal_id, name:          :idx_tool_calls_identity_principal_id,
                                        where:         Sequel.negate(identity_principal_id: nil),
                                        ignore_errors: true
    end
  end
end
