# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Models
      module LLM
        class RouteAttempt < Sequel::Model(:llm_route_attempts)
          include ModelHelpers

          many_to_one :message_inference_request
          many_to_one :message_inference_response
        end
      end
    end
  end
end
