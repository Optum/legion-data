# frozen_string_literal: true

require 'legion/logging/helper'
require_relative 'extract/type_detector'
require_relative 'extract/handlers/base'

module Legion
  module Data
    module Extract
      class << self
        include Legion::Logging::Helper

        def extract(source, type: :auto)
          detected_type = type == :auto ? TypeDetector.detect(source) : type&.to_sym
          return { success: false, text: nil, error: :unknown_type } unless detected_type

          handler = Handlers::Base.for_type(detected_type)
          return { success: false, text: nil, error: :no_handler, type: detected_type } unless handler

          unless handler.available?
            return { success: false, text: nil, error: :gem_not_installed,
                     gem: handler.gem_name, type: detected_type }
          end

          log.info "Extract starting type=#{detected_type} handler=#{handler.name}"
          result = handler.extract(source)
          if result[:text]
            log.info "Extract succeeded type=#{detected_type}"
            { success: true, text: result[:text], metadata: result[:metadata], type: detected_type }
          else
            log.warn "Extract failed type=#{detected_type} error=#{result[:error]}"
            { success: false, text: nil, error: result[:error], type: detected_type }
          end
        rescue StandardError => e
          handle_exception(e, level: :error, handled: true, operation: :extract, type: detected_type)
          { success: false, text: nil, error: e.message, type: detected_type }
        end

        def supported_types
          load_all_handlers
          Handlers::Base.supported_types
        end

        def can_extract?(type)
          load_all_handlers
          handler = Handlers::Base.for_type(type&.to_sym)
          handler&.available? || false
        end

        def register_handler(type, klass)
          Handlers::Base.instance_variable_set(:@registry,
                                               Handlers::Base.registry.merge(type.to_sym => klass).freeze)
        end

        private

        def load_all_handlers
          return if @handlers_loaded

          Dir[File.join(__dir__, 'extract', 'handlers', '*.rb')].each do |f|
            require f unless f.end_with?('base.rb')
          end
          @handlers_loaded = true
        end
      end
    end
  end
end
