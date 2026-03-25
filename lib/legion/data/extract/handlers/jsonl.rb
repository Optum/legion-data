# frozen_string_literal: true

require 'json'

module Legion
  module Data
    module Extract
      module Handlers
        class Jsonl < Base
          def self.type = :jsonl
          def self.extensions = %w[.jsonl]
          def self.gem_name = nil

          def self.extract(source)
            content = source.respond_to?(:read) ? source.read : File.read(source.to_s)
            lines = content.each_line.map { |l| ::JSON.parse(l.strip) rescue l.strip } # rubocop:disable Style/RescueModifier
            text = lines.map { |l| l.is_a?(Hash) ? ::JSON.pretty_generate(l) : l }.join("\n---\n")
            { text: text, metadata: { lines: lines.size } }
          rescue StandardError => e
            { text: nil, error: e.message }
          end
        end
      end
    end
  end
end
