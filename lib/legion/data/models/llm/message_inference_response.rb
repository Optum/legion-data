# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Models
      module LLM
        class MessageInferenceResponse < Sequel::Model(:llm_message_inference_responses)
          include ModelHelpers

          many_to_one :message_inference_request
          many_to_one :response_message, class: 'Legion::Data::Models::LLM::Message', key: :response_message_id
          one_to_many :route_attempts
          one_to_many :message_inference_metrics
          one_to_many :tool_calls
          one_to_many :policy_evaluations
          one_to_many :security_events
        end
      end
    end
  end
end
