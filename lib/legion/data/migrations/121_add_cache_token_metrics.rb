# frozen_string_literal: true

Sequel.migration do
  up do
    next unless table_exists?(:llm_message_inference_metrics)

    existing = schema(:llm_message_inference_metrics).map(&:first)

    alter_table(:llm_message_inference_metrics) do
      add_column :cached_input_tokens, Integer, null: false, default: 0 unless existing.include?(:cached_input_tokens)
      add_column :cache_creation_tokens, Integer, null: false, default: 0 unless existing.include?(:cache_creation_tokens)
    end
  end

  down do
    next unless table_exists?(:llm_message_inference_metrics)

    alter_table(:llm_message_inference_metrics) do
      drop_column :cache_creation_tokens
      drop_column :cached_input_tokens
    end
  end
end
