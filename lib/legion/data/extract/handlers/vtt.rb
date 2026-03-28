# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Vtt < Base
          TIMESTAMP_PATTERN = /^\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}/
          SPEAKER_TAG_PATTERN = /^<v ([^>]+)>(.*)$/

          def self.type = :vtt
          def self.extensions = %w[.vtt]
          def self.gem_name = nil

          def self.extract(source, preserve_speakers: true)
            content = if source.respond_to?(:read)
                        source.read
                      elsif source.is_a?(String) && source.include?("\n")
                        source
                      else
                        File.read(source.to_s)
                      end
            lines = parse_vtt(content, preserve_speakers: preserve_speakers)
            text = lines.join("\n")
            speakers = extract_speakers(content)
            {
              text:     text,
              metadata: {
                bytes:      content.bytesize,
                speakers:   speakers,
                line_count: lines.size
              }
            }
          rescue StandardError => e
            { text: nil, error: e.message }
          end

          def self.parse_vtt(content, preserve_speakers: true)
            lines = []
            content.each_line do |raw|
              line = raw.strip
              next if line.empty?
              next if line == 'WEBVTT'
              next if TIMESTAMP_PATTERN.match?(line)

              if (match = SPEAKER_TAG_PATTERN.match(line))
                speaker = match[1].strip
                text = match[2].strip
                lines << (preserve_speakers ? "#{speaker}: #{text}" : text)
              else
                lines << line
              end
            end
            lines
          end

          def self.extract_speakers(content)
            content.scan(SPEAKER_TAG_PATTERN).map { |m| m[0].strip }.uniq
          end
          private_class_method :parse_vtt, :extract_speakers
        end
      end
    end
  end
end
