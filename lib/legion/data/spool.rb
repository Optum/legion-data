# frozen_string_literal: true

require 'legion/logging/helper'
require 'json'
require 'fileutils'
require 'securerandom'

module Legion
  module Data
    module Spool
      EXTENSION_PREFIX = 'Legion::Extensions::'
      LEGION_PREFIX    = 'Legion::'

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
          if name&.start_with?(EXTENSION_PREFIX)
            name.delete_prefix(EXTENSION_PREFIX).gsub('::', '/').downcase
          elsif name&.start_with?(LEGION_PREFIX)
            name.delete_prefix(LEGION_PREFIX).gsub('::', '/').downcase
          else
            raise ArgumentError, "#{name} is not under the Legion:: namespace"
          end
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
          temp_path = temp_path_for(dir, filename)
          File.binwrite(temp_path, ::JSON.generate(payload))
          File.rename(temp_path, path)
          log.info "Spool write: #{sub_namespace} -> #{filename}"
          path
        rescue StandardError => e
          File.delete(temp_path) if defined?(temp_path) && temp_path && File.exist?(temp_path)
          handle_exception(e, level: :error, handled: false, operation: :spool_write, sub_namespace: sub_namespace)
          raise
        end

        def read(sub_namespace)
          sorted_files(sub_namespace).each_with_object([]) do |path, events|
            event = load_event_file(path, sub_namespace)
            events << event if event
          end
        rescue StandardError => e
          handle_exception(e, level: :error, handled: false, operation: :spool_read, sub_namespace: sub_namespace)
          raise
        end

        def flush(sub_namespace)
          count = 0
          path = nil
          sorted_files(sub_namespace).each do |path|
            event = load_event_file(path, sub_namespace)
            next unless event

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

          Dir.glob(File.join(dir, '*.json'), sort: true)
        end

        def load_event_file(path, sub_namespace)
          ::JSON.parse(File.binread(path), symbolize_names: true)
        rescue Errno::ENOENT
          nil
        rescue ::JSON::ParserError, EOFError, ArgumentError => e
          quarantine_corrupt_file(path, sub_namespace, e)
          nil
        end

        def quarantine_corrupt_file(path, sub_namespace, error)
          return unless File.exist?(path)

          quarantine_dir = File.join(sub_dir(sub_namespace), 'quarantine')
          FileUtils.mkdir_p(quarantine_dir)
          quarantine_path = unique_quarantine_path(quarantine_dir, File.basename(path))
          File.rename(path, quarantine_path)
          handle_exception(
            error,
            level:           :warn,
            handled:         true,
            operation:       :spool_quarantine,
            sub_namespace:   sub_namespace,
            path:            path,
            quarantine_path: quarantine_path
          )
        end

        def unique_quarantine_path(quarantine_dir, basename)
          path = File.join(quarantine_dir, "#{basename}.corrupt")
          return path unless File.exist?(path)

          File.join(quarantine_dir, "#{basename}.#{SecureRandom.uuid}.corrupt")
        end

        def temp_path_for(dir, filename)
          File.join(dir, ".#{filename}.tmp-#{SecureRandom.uuid}")
        end
      end
    end
  end
end
