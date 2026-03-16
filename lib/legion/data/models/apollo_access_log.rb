# frozen_string_literal: true

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class ApolloAccessLog < Sequel::Model(:apollo_access_log)
        many_to_one :entry, class: 'Legion::Data::Model::ApolloEntry', key: :entry_id
      end
    end
  end
end
