# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Xlsx < Base
          def self.type = :xlsx
          def self.extensions = %w[.xlsx .xls]
          def self.gem_name = 'rubyXL'

          def self.extract(source)
            require 'rubyXL'
            require 'rubyXL/convenience_methods'

            workbook = ::RubyXL::Parser.parse(source)
            sheets = []
            workbook.worksheets.each do |sheet|
              rows = sheet.each.map do |row|
                next unless row

                row.cells.map { |c| c&.value.to_s }.join(', ')
              end.compact
              sheets << "Sheet: #{sheet.sheet_name}\n#{rows.join("\n")}" unless rows.empty?
            end
            text = sheets.join("\n\n")
            { text: text, metadata: { sheets: workbook.worksheets.size } }
          rescue LoadError
            { text: nil, error: :gem_not_installed, gem: gem_name }
          rescue StandardError => e
            { text: nil, error: e.message }
          end
        end
      end
    end
  end
end
