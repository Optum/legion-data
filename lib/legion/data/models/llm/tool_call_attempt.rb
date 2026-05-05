# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class ToolCallAttempt < Sequel::Model(:llm_tool_call_attempts)
          include ModelHelpers

          many_to_one :tool_call
          one_to_many :security_events
        end
      end
    end
  end
end
