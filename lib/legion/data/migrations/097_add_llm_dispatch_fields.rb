# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:llm_message_inference_requests) do
      add_column :operation, String, size: 64, null: false, default: 'chat'
      add_column :correlation_id, String, size: 64
      add_column :idempotency_key, String, size: 128
    end

    alter_table(:llm_message_inference_responses) do
      add_column :provider_instance, String, size: 128
      add_column :dispatch_path, String, size: 32
    end
  end
end
