# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Html < Base
          def self.type = :html
          def self.extensions = %w[.html .htm]
          def self.gem_name = 'nokogiri'

          def self.extract(source)
            require 'nokogiri'

            content = source.respond_to?(:read) ? source.read : File.read(source.to_s)
            doc = ::Nokogiri::HTML(content)

            # Remove script and style elements
            doc.css('script, style, noscript').each(&:remove)

            title = doc.at_css('title')&.text&.strip
            text = doc.text.gsub(/\s+/, ' ').strip
            { text: text, metadata: { title: title } }
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
