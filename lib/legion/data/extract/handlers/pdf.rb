# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Pdf < Base
          def self.type = :pdf
          def self.extensions = %w[.pdf]
          def self.gem_name = 'pdf-reader'

          def self.extract(source)
            require 'pdf-reader'

            reader = ::PDF::Reader.new(source)
            text = reader.pages.map(&:text).join("\n\n")
            { text: text, metadata: { pages: reader.page_count, title: reader.info[:Title] } }
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
