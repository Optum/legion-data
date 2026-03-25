# frozen_string_literal: true

module Legion
  module Data
    module Extract
      module Handlers
        class Base
          @registry = {}

          class << self
            attr_reader :registry

            def inherited(subclass)
              super
              # Deferred registration — subclass defines type after class body loads
              TracePoint.new(:end) do |tp|
                if tp.self == subclass
                  register(subclass) if subclass.respond_to?(:type) && subclass.type
                  tp.disable
                end
              end.enable
            end

            def register(handler_class)
              @registry[handler_class.type] = handler_class
            end

            def for_type(type)
              @registry[type&.to_sym]
            end

            def supported_types
              @registry.keys
            end

            # Override in subclasses
            def type = nil
            def extensions = []
            def gem_name = nil

            def extract(_source)
              raise NotImplementedError, "#{name} must implement .extract"
            end

            def available?
              return true if gem_name.nil?

              require gem_name
              true
            rescue LoadError
              false
            end
          end
        end
      end
    end
  end
end
