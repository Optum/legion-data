# frozen_string_literal: true

return unless Legion::Data::Connection.adapter == :postgres

module Legion
  module Data
    module Model
      class ApolloExpertise < Sequel::Model(:apollo_expertise)
      end
    end
  end
end
