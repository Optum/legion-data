# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:llm_message_inference_requests) do
      add_column :runtime_caller_class, String, size: 255, null: true, index: true
      add_column :runtime_caller_client, String, size: 255, null: true
    end
  end

  down do
    alter_table(:llm_message_inference_requests) do
      drop_index :runtime_caller_class
      drop_column :runtime_caller_class
      drop_column :runtime_caller_client
    end
  end
end
