# frozen_string_literal: true

# Migration 103: Add standardized identity columns to all LLM lifecycle tables.
#
# Tables receiving the full set of four new columns (access_scope, identity_principal_id,
# identity_id, identity_canonical_name):
#   - llm_messages (078)
#   - llm_message_inference_responses (080)
#   - llm_message_inference_metrics (083)
#   - llm_tool_calls (084)
#   - llm_tool_call_attempts (086)
#   - llm_policy_evaluations (088)
#   - llm_security_events (089)
#   - llm_registry_events (090)
#   - llm_route_attempts (082)
#   - llm_conversation_compactions (087)
#
# Tables receiving only the two missing columns (access_scope and identity_canonical_name,
# because principal_id/identity_id variants already exist under their original names):
#   - llm_conversations (077) — has principal_id and identity_id
#   - llm_message_inference_requests (079) — has caller_principal_id and caller_identity_id
#
# Existing columns (principal_id, identity_id, caller_principal_id, caller_identity_id)
# are NOT renamed — they are in active use by lex-llm-ledger's OfficialRecordWriter.
#
# Indexes: full index on access_scope, partial index on identity_principal_id
# (WHERE identity_principal_id IS NOT NULL) for every table that receives the full set.
# llm_conversations and llm_message_inference_requests get access_scope indexes only,
# because their principal/identity columns already have indexes under the old names.

Sequel.migration do
  up do
    # -----------------------------------------------------------------------
    # Tables receiving the FULL set of four identity columns
    # -----------------------------------------------------------------------
    %i[
      llm_messages
      llm_message_inference_responses
      llm_message_inference_metrics
      llm_tool_calls
      llm_tool_call_attempts
      llm_policy_evaluations
      llm_security_events
      llm_registry_events
      llm_route_attempts
      llm_conversation_compactions
    ].each do |table|
      alter_table(table) do
        add_column :access_scope,            String,  size: 20, null: false, default: 'global'
        add_column :identity_principal_id,   Integer, null: true
        add_column :identity_id,             Integer, null: true
        add_column :identity_canonical_name, String,  size: 255, null: true
      end
    end

    # -----------------------------------------------------------------------
    # Tables receiving only the TWO missing columns
    # (access_scope + identity_canonical_name; principal/identity cols exist)
    # -----------------------------------------------------------------------
    %i[
      llm_conversations
      llm_message_inference_requests
    ].each do |table|
      alter_table(table) do
        add_column :access_scope,            String, size: 20,  null: false, default: 'global'
        add_column :identity_canonical_name, String, size: 255, null: true
      end
    end

    # -----------------------------------------------------------------------
    # Indexes — full-set tables
    # -----------------------------------------------------------------------
    %i[
      llm_messages
      llm_message_inference_responses
      llm_message_inference_metrics
      llm_tool_calls
      llm_tool_call_attempts
      llm_policy_evaluations
      llm_security_events
      llm_registry_events
      llm_route_attempts
      llm_conversation_compactions
    ].each do |table|
      short = table.to_s.sub('llm_', '')

      run "CREATE INDEX IF NOT EXISTS idx_#{short}_access_scope ON #{table} (access_scope)"
      run "CREATE INDEX IF NOT EXISTS idx_#{short}_identity_principal_id ON #{table} (identity_principal_id) WHERE identity_principal_id IS NOT NULL"
    end

    # access_scope indexes for the two partially-updated tables
    run 'CREATE INDEX IF NOT EXISTS idx_conversations_access_scope ON llm_conversations (access_scope)'
    run 'CREATE INDEX IF NOT EXISTS idx_inference_requests_access_scope ON llm_message_inference_requests (access_scope)'
  end

  down do
    # -----------------------------------------------------------------------
    # Drop indexes — full-set tables
    # -----------------------------------------------------------------------
    %i[
      llm_messages
      llm_message_inference_responses
      llm_message_inference_metrics
      llm_tool_calls
      llm_tool_call_attempts
      llm_policy_evaluations
      llm_security_events
      llm_registry_events
      llm_route_attempts
      llm_conversation_compactions
    ].each do |table|
      short = table.to_s.sub('llm_', '')

      run "DROP INDEX IF EXISTS idx_#{short}_access_scope"
      run "DROP INDEX IF EXISTS idx_#{short}_identity_principal_id"
    end

    run 'DROP INDEX IF EXISTS idx_conversations_access_scope'
    run 'DROP INDEX IF EXISTS idx_inference_requests_access_scope'

    # -----------------------------------------------------------------------
    # Drop columns — full-set tables
    # -----------------------------------------------------------------------
    %i[
      llm_messages
      llm_message_inference_responses
      llm_message_inference_metrics
      llm_tool_calls
      llm_tool_call_attempts
      llm_policy_evaluations
      llm_security_events
      llm_registry_events
      llm_route_attempts
      llm_conversation_compactions
    ].each do |table|
      alter_table(table) do
        drop_column :access_scope
        drop_column :identity_principal_id
        drop_column :identity_id
        drop_column :identity_canonical_name
      end
    end

    # -----------------------------------------------------------------------
    # Drop columns — partial tables
    # -----------------------------------------------------------------------
    %i[
      llm_conversations
      llm_message_inference_requests
    ].each do |table|
      alter_table(table) do
        drop_column :access_scope
        drop_column :identity_canonical_name
      end
    end
  end
end
