# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_message_inference_requests)

    existing = schema(:llm_message_inference_requests).map(&:first)
    next if existing.include?(:parent_request_id)

    alter_table(:llm_message_inference_requests) do
      add_foreign_key :parent_request_id, :llm_message_inference_requests, null: true, on_delete: :set_null
    end
  end

  down do
    next unless table_exists?(:llm_message_inference_requests)

    alter_table(:llm_message_inference_requests) do
      drop_foreign_key :parent_request_id
    end
  end
end
