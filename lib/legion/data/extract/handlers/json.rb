# frozen_string_literal: true

require 'json'

module Legion
  module Data
    module Extract
      module Handlers
        class Json < Base
          def self.type = :json
          def self.extensions = %w[.json]
          def self.gem_name = nil

          def self.extract(source)
            content = source.respond_to?(:read) ? source.read : File.read(source.to_s)
            parsed = ::JSON.parse(content)
            text = ::JSON.pretty_generate(parsed)
            { text: text, metadata: { keys: parsed.is_a?(Hash) ? parsed.keys : nil } }
          rescue StandardError => e
            { text: nil, error: e.message }
          end
        end
      end
    end
  end
end
