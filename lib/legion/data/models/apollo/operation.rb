# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Apollo::ModelHelpers.table_available?(:apollo_operations)

module Legion
  module Data
    module Model
      module Apollo
        class Operation < Sequel::Model(:apollo_operations)
        end
      end
    end
  end
end
