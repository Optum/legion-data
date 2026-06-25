# frozen_string_literal: true

require 'csv'

module Legion
  module Data
    module Extract
      module Handlers
        class Csv < Base
          def self.type = :csv
          def self.extensions = %w[.csv]
          def self.gem_name = nil

          def self.extract(source)
            content = source.respond_to?(:read) ? source.read : File.read(source.to_s)
            table = ::CSV.parse(content, headers: true)
            text = table.map { |row| row.to_h.map { |k, v| "#{k}: #{v}" }.join(', ') }.join("\n")
            { text: text, metadata: { rows: table.size, columns: table.headers.size, headers: table.headers } }
          rescue StandardError => e
            handle_exception(e, level: :warn, handled: true, operation: :extract_csv)
            { text: nil, error: e.message }
          end
        end
      end
    end
  end
end
