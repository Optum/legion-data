# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Pptx < Base
          def self.type = :pptx
          def self.extensions = %w[.pptx]
          def self.gem_name = 'rubyzip'

          def self.extract(source)
            require 'zip'
            require 'rexml/document'

            slides = []
            ::Zip::File.open(source) do |zip|
              zip.glob('ppt/slides/slide*.xml').sort_by(&:name).each do |entry|
                doc = REXML::Document.new(entry.get_input_stream.read)
                texts = []
                doc.each_element('//a:t') { |e| texts << e.text }
                slides << texts.join(' ') unless texts.empty?
              end
            end
            text = slides.each_with_index.map { |s, i| "Slide #{i + 1}: #{s}" }.join("\n\n")
            { text: text, metadata: { slides: slides.size } }
          rescue LoadError
            { text: nil, error: :gem_not_installed, gem: 'rubyzip' }
          rescue StandardError => e
            { text: nil, error: e.message }
          end
        end
      end
    end
  end
end
