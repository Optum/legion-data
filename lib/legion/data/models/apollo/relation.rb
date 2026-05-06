# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Apollo::ModelHelpers.table_available?(:apollo_relations)

module Legion
  module Data
    module Model
      module Apollo
        class Relation < Sequel::Model(:apollo_relations)
          many_to_one :from_entry, class: 'Legion::Data::Model::Apollo::Entry', key: :from_entry_id
          many_to_one :to_entry, class: 'Legion::Data::Model::Apollo::Entry', key: :to_entry_id
        end
      end
    end
  end
end
