# frozen_string_literal: true

require_relative 'model_helpers'

return unless Legion::Data::Model::Apollo::ModelHelpers.table_available?(:apollo_access_log)

module Legion
  module Data
    module Model
      module Apollo
        class AccessLog < Sequel::Model(:apollo_access_log)
          many_to_one :entry, class: 'Legion::Data::Model::Apollo::Entry', key: :entry_id
        end
      end
    end
  end
end
