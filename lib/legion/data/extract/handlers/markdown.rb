# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Markdown < Base
          def self.type = :markdown
          def self.extensions = %w[.md .markdown]
          def self.gem_name = nil

          def self.extract(source)
            content = source.respond_to?(:read) ? source.read : File.read(source.to_s)
            # Strip YAML frontmatter if present
            text = content.sub(/\A---\n.*?\n---\n/m, '')
            { text: text.strip, metadata: { bytes: content.bytesize, has_frontmatter: content != text } }
          rescue StandardError => e
            handle_exception(e, level: :warn, handled: true, operation: :extract_markdown)
            { text: nil, error: e.message }
          end
        end
      end
    end
  end
end
