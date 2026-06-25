# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Models
      module LLM
        class ContextAccountingEvent < Sequel::Model(:llm_context_accounting_events)
          include ModelHelpers

          many_to_one :message_inference_request
          many_to_one :message_inference_response
          many_to_one :message_inference_metric
        end
      end
    end
  end
end
