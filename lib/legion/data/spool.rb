# frozen_string_literal: true

require 'legion/logging/helper'
require 'json'
require 'fileutils'
require 'securerandom'

module Legion
  module Data
    module Spool
      EXTENSION_PREFIX = 'Legion::Extensions::'

      class << self
        def root
          @root ||= File.expand_path('~/.legionio/data/spool')
        end

        attr_writer :root

        def for(extension_module)
          ScopedSpool.new(extension_module, root)
        end

        private

        def extension_path(extension_module)
          name = extension_module.name
          raise ArgumentError, "#{name} is not under Legion::Extensions::" unless name&.start_with?(EXTENSION_PREFIX)

          name.delete_prefix(EXTENSION_PREFIX).gsub('::', '/').downcase
        end
      end

      class ScopedSpool
        include Legion::Logging::Helper

        def initialize(extension_module, spool_root)
          @extension_dir = File.join(spool_root, Spool.send(:extension_path, extension_module))
        end

        def write(sub_namespace, payload)
          dir = sub_dir(sub_namespace)
          FileUtils.mkdir_p(dir)
          filename = "#{Time.now.strftime('%s%9N')}-#{SecureRandom.uuid}.json"
          path = File.join(dir, filename)
          File.write(path, ::JSON.generate(payload))
          log.info "Spool write: #{sub_namespace} -> #{filename}"
          path
        rescue StandardError => e
          handle_exception(e, level: :error, handled: false, operation: :spool_write, sub_namespace: sub_namespace)
          raise
        end

        def read(sub_namespace)
          sorted_files(sub_namespace).map { |f| ::JSON.parse(File.read(f), symbolize_names: true) }
        rescue StandardError => e
          handle_exception(e, level: :error, handled: false, operation: :spool_read, sub_namespace: sub_namespace)
          raise
        end

        def flush(sub_namespace)
          count = 0
          path = nil
          sorted_files(sub_namespace).each do |path|
            event = ::JSON.parse(File.read(path), symbolize_names: true)
            yield event
            File.delete(path)
            count += 1
          end
          log.info "Spool drained #{count} item(s) from #{sub_namespace}" if count.positive?
          count
        rescue StandardError => e
          handle_exception(e, level: :error, handled: false, operation: :spool_flush, sub_namespace: sub_namespace, path: path)
          raise
        end

        def count(sub_namespace)
          sorted_files(sub_namespace).size
        end

        def clear(sub_namespace)
          dir = sub_dir(sub_namespace)
          return unless Dir.exist?(dir)

          Dir[File.join(dir, '*.json')].each { |f| File.delete(f) }
          log.info "Spool cleared #{sub_namespace}"
        rescue StandardError => e
          handle_exception(e, level: :error, handled: false, operation: :spool_clear, sub_namespace: sub_namespace)
          raise
        end

        private

        def sub_dir(sub_namespace)
          File.join(@extension_dir, sub_namespace.to_s)
        end

        def sorted_files(sub_namespace)
          dir = sub_dir(sub_namespace)
          return [] unless Dir.exist?(dir)

          Dir[File.join(dir, '*.json')]
        end
      end
    end
  end
end
