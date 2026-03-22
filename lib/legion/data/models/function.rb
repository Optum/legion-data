# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Function < Sequel::Model
        many_to_one :runner
        one_to_many :trigger_relationships, class: 'Legion::Data::Model::Relationship', key: :trigger_id
        one_to_many :action_relationships, class: 'Legion::Data::Model::Relationship', key: :action_id

        def embedding_vector
          return nil unless embedding

          ::JSON.parse(embedding)
        rescue ::JSON::ParserError => e
          Legion::Logging.debug("Function#embedding_vector JSON parse failed: #{e.message}") if defined?(Legion::Logging)
          nil
        end

        def embedding_vector=(vec)
          self.embedding = vec&.to_json
        end
      end
    end
  end
end
