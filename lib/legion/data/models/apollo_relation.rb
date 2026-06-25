# frozen_string_literal: true

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class ApolloRelation < Sequel::Model(:apollo_relations)
        many_to_one :from_entry, class: 'Legion::Data::Model::ApolloEntry', key: :from_entry_id
        many_to_one :to_entry, class: 'Legion::Data::Model::ApolloEntry', key: :to_entry_id
      end
    end
  end
end
