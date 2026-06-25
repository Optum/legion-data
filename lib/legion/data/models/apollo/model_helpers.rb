# frozen_string_literal: true

module Legion
  module Data
    module Model
      module Apollo
        module ModelHelpers
          def self.table_available?(table_name)
            Legion::Data::Connection.sequel&.table_exists?(table_name)
          rescue StandardError => e
            log.error("table availability check failed for #{table_name}: #{e.message}")
            false
          end
        end
      end
    end
  end
end
