# frozen_string_literal: true

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class ApolloEntry < Sequel::Model(:apollo_entries)
        one_to_many :outgoing_relations, class: 'Legion::Data::Model::ApolloRelation',
                                         key:   :from_entry_id
        one_to_many :incoming_relations, class: 'Legion::Data::Model::ApolloRelation',
                                         key:   :to_entry_id
        one_to_many :access_logs, class: 'Legion::Data::Model::ApolloAccessLog',
                                  key:   :entry_id
      end
    end
  end
end
