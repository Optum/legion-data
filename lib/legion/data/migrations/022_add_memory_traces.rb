# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:memory_traces) do
      primary_key :id
      String :agent_id, null: false, size: 64, index: true
      String :trace_type, null: false, size: 32
      String :content, text: true, null: false
      Float :significance, default: 0.5
      Float :confidence, default: 1.0
      String :associations, text: true
      String :metadata, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :accessed_at
      DateTime :decayed_at
      index %i[agent_id trace_type]
    end

    next unless adapter_scheme == :postgres

    run 'ALTER TABLE memory_traces ADD COLUMN IF NOT EXISTS embedding vector(1536)'
    run 'CREATE INDEX IF NOT EXISTS idx_memory_traces_embedding ON memory_traces USING hnsw (embedding vector_cosine_ops)'
  end

  down do
    drop_table?(:memory_traces)
  end
end
