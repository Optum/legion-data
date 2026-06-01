# frozen_string_literal: true

# Add cached_input_tokens and cache_creation_tokens to llm_message_inference_metrics.
# Tracks cache hit tokens (read from cache) and cache write tokens separately from
# standard input/output token counts.
#
# See: https://github.com/LegionIO/legion-data/issues/55

Sequel.migration do
  up do
    alter_table(:llm_message_inference_metrics) do
      add_column :cached_input_tokens, Integer, null: false, default: 0
      add_column :cache_creation_tokens, Integer, null: false, default: 0
    end
  end

  down do
    alter_table(:llm_message_inference_metrics) do
      drop_column :cache_creation_tokens
      drop_column :cached_input_tokens
    end
  end
end
