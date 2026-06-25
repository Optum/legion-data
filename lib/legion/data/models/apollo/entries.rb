# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Apollo::ModelHelpers.table_available?(:apollo_entries)

module Legion
  module Data
    module Model
      module Apollo
        class Entry < Sequel::Model(:apollo_entries)
          one_to_many :outgoing_relations, class: 'Legion::Data::Model::Apollo::Relation',
                                           key:   :from_entry_id
          one_to_many :incoming_relations, class: 'Legion::Data::Model::Apollo::Relation',
                                           key:   :to_entry_id
          one_to_many :access_logs, class: 'Legion::Data::Model::Apollo::AccessLog',
                                    key:   :entry_id
        end
      end
    end
  end
end
