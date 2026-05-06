# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Apollo::ModelHelpers.table_available?(:apollo_expertise)

module Legion
  module Data
    module Model
      module Apollo
        class Expertise < Sequel::Model(:apollo_expertise)
        end
      end
    end
  end
end
