# frozen_string_literal: true

module Legion
  module Data
    module Vector
      class << self
        def available?
          return false unless Legion::Data.connection
          return false unless Legion::Data.connection.adapter_scheme == :postgres

          Legion::Data.connection.fetch("SELECT 1 FROM pg_extension WHERE extname = 'vector'").any?
        rescue StandardError
          false
        end

        def ensure_extension!
          return false unless Legion::Data.connection&.adapter_scheme == :postgres

          Legion::Data.connection.run('CREATE EXTENSION IF NOT EXISTS vector')
          true
        rescue StandardError => e
          Legion::Logging.warn("pgvector extension creation failed: #{e.message}") if defined?(Legion::Logging)
          false
        end

        def cosine_search(table:, column:, query_vector:, limit: 10, min_similarity: 0.0)
          return [] unless available?

          vec_literal = vector_literal(query_vector)
          ds = Legion::Data.connection[table]
                           .select_all
                           .select_append(Sequel.lit("1 - (#{column} <=> ?)", vec_literal).as(:similarity))
                           .order(Sequel.lit("#{column} <=> ?", vec_literal))
                           .limit(limit)

          ds = ds.where(Sequel.lit("1 - (#{column} <=> ?) >= ?", vec_literal, min_similarity)) if min_similarity.positive?
          ds.all
        end

        def l2_search(table:, column:, query_vector:, limit: 10)
          return [] unless available?

          vec_literal = vector_literal(query_vector)
          Legion::Data.connection[table]
                      .select_all
                      .select_append(Sequel.lit("#{column} <-> ?", vec_literal).as(:distance))
                      .order(Sequel.lit("#{column} <-> ?", vec_literal))
                      .limit(limit)
                      .all
        end

        private

        def vector_literal(query_vector)
          "[#{query_vector.join(',')}]"
        end
      end
    end
  end
end
