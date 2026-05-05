# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class RegistryEvent < Sequel::Model(:llm_registry_events)
          include ModelHelpers
        end
      end
    end
  end
end
