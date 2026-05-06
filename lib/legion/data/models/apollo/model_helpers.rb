# frozen_string_literal: true

module Legion
  module Data
    module Model
      module Apollo
        module ModelHelpers
          def self.table_available?(table_name)
            Legion::Data::Connection.sequel&.table_exists?(table_name)
          rescue StandardError
            false
          end
        end
      end
    end
  end
end
