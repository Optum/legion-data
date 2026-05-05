# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class PolicyEvaluation < Sequel::Model(:llm_policy_evaluations)
          include ModelHelpers

          many_to_one :conversation
          many_to_one :message_inference_request
          many_to_one :message_inference_response
          one_to_many :security_events
        end
      end
    end
  end
end
