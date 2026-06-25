# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:functions) do
      add_column :description, String, text: true, null: true
      add_column :embedding, String, text: true, null: true
    end

    next unless adapter_scheme == :postgres

    run 'ALTER TABLE functions ADD COLUMN IF NOT EXISTS embedding_vector vector(1536)'
    run 'CREATE INDEX IF NOT EXISTS idx_functions_embedding ON functions USING hnsw (embedding_vector vector_cosine_ops)'
  end

  down do
    alter_table(:functions) do
      drop_column :embedding
      drop_column :description
    end

    if adapter_scheme == :postgres
      run 'DROP INDEX IF EXISTS idx_functions_embedding'
      run 'ALTER TABLE functions DROP COLUMN IF EXISTS embedding_vector'
    end
  end
end
