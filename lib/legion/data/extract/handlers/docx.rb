# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Docx < Base
          def self.type = :docx
          def self.extensions = %w[.docx]
          def self.gem_name = 'docx'

          def self.extract(source)
            require 'docx'

            doc = ::Docx::Document.open(source)
            paragraphs = doc.paragraphs.map(&:text).reject(&:empty?)
            text = paragraphs.join("\n\n")
            { text: text, metadata: { paragraphs: paragraphs.size } }
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
