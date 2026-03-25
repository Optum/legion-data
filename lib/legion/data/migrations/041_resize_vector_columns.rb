# frozen_string_literal: true

Sequel.migration do
  up do
    next unless adapter_scheme == :postgres

    # Resize embedding columns from 1536 to 1024 for cross-provider compatibility
    # (Bedrock Titan v2, OpenAI with dimensions:, Ollama mxbai-embed-large all support 1024)
    # Knowledge store is empty so no data re-embedding needed.

    if table_exists?(:apollo_entries)
      run 'DROP INDEX IF EXISTS idx_apollo_entries_embedding'
      run 'ALTER TABLE apollo_entries ALTER COLUMN embedding TYPE vector(1024)'
      run 'CREATE INDEX idx_apollo_entries_embedding ON apollo_entries USING hnsw (embedding vector_cosine_ops)'
    end

    if table_exists?(:functions)
      run 'DROP INDEX IF EXISTS idx_functions_embedding'
      run 'ALTER TABLE functions ALTER COLUMN embedding_vector TYPE vector(1024)'
      run 'CREATE INDEX idx_functions_embedding ON functions USING hnsw (embedding_vector vector_cosine_ops)'
    end

    if table_exists?(:memory_traces)
      run 'DROP INDEX IF EXISTS idx_memory_traces_embedding'
      run 'ALTER TABLE memory_traces ALTER COLUMN embedding TYPE vector(1024)'
      run 'CREATE INDEX idx_memory_traces_embedding ON memory_traces USING hnsw (embedding vector_cosine_ops)'
    end
  end

  down do
    next unless adapter_scheme == :postgres

    if table_exists?(:apollo_entries)
      run 'DROP INDEX IF EXISTS idx_apollo_entries_embedding'
      run 'ALTER TABLE apollo_entries ALTER COLUMN embedding TYPE vector(1536)'
      run 'CREATE INDEX idx_apollo_entries_embedding ON apollo_entries USING hnsw (embedding vector_cosine_ops)'
    end

    if table_exists?(:functions)
      run 'DROP INDEX IF EXISTS idx_functions_embedding'
      run 'ALTER TABLE functions ALTER COLUMN embedding_vector TYPE vector(1536)'
      run 'CREATE INDEX idx_functions_embedding ON functions USING hnsw (embedding_vector vector_cosine_ops)'
    end

    if table_exists?(:memory_traces)
      run 'DROP INDEX IF EXISTS idx_memory_traces_embedding'
      run 'ALTER TABLE memory_traces ALTER COLUMN embedding TYPE vector(1536)'
      run 'CREATE INDEX idx_memory_traces_embedding ON memory_traces USING hnsw (embedding vector_cosine_ops)'
    end
  end
end
