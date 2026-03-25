# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Text < Base
          def self.type = :text
          def self.extensions = %w[.txt]
          def self.gem_name = nil

          def self.extract(source)
            content = source.respond_to?(:read) ? source.read : File.read(source.to_s)
            { text: content, metadata: { bytes: content.bytesize } }
          rescue StandardError => e
            { text: nil, error: e.message }
          end
        end
      end
    end
  end
end
