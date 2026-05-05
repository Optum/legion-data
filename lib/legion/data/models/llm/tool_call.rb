# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class ToolCall < Sequel::Model(:llm_tool_calls)
          include ModelHelpers

          many_to_one :message_inference_response
          many_to_one :requested_by_message, class: 'Legion::Data::Model::LLM::Message', key: :requested_by_message_id
          many_to_one :result_message, class: 'Legion::Data::Model::LLM::Message', key: :result_message_id
          one_to_many :tool_call_attempts
          one_to_many :security_events
        end
      end
    end
  end
end
