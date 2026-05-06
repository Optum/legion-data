# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Models
      module LLM
        class SecurityEvent < Sequel::Model(:llm_security_events)
          include ModelHelpers

          many_to_one :conversation
          many_to_one :message_inference_request
          many_to_one :message_inference_response
          many_to_one :tool_call
          many_to_one :tool_call_attempt
          many_to_one :policy_evaluation

          class << self
            def lineage_for_conversation(conversation_or_id)
              conversation_id = conversation_or_id.respond_to?(:id) ? conversation_or_id.id : conversation_or_id
              requests = MessageInferenceRequest.where(conversation_id: conversation_id).order(:id).all
              request_ids = requests.map(&:id)
              responses = MessageInferenceResponse.where(message_inference_request_id: request_ids).order(:id).all
              response_ids = responses.map(&:id)
              tool_calls = ToolCall.where(message_inference_response_id: response_ids).order(:tool_call_index, :id).all
              tool_call_ids = tool_calls.map(&:id)

              {
                conversation:            Conversation[conversation_id],
                messages:                Message.where(conversation_id: conversation_id).order(:seq, :id).all,
                requests:                requests,
                route_attempts:          RouteAttempt.where(message_inference_request_id: request_ids).order(:message_inference_request_id, :attempt_no,
                                                                                                             :id).all,
                responses:               responses,
                request_payload_hashes:  requests.filter_map(&:request_content_hash),
                response_payload_hashes: responses.filter_map(&:response_content_hash),
                policy_evaluations:      policy_evaluations_for(conversation_id, request_ids, response_ids),
                security_events:         security_events_for(conversation_id, request_ids, response_ids, tool_call_ids),
                tool_calls:              tool_calls,
                tool_call_attempts:      ToolCallAttempt.where(tool_call_id: tool_call_ids).order(:tool_call_id, :attempt_no, :id).all
              }
            end

            private

            def policy_evaluations_for(conversation_id, request_ids, response_ids)
              scope = PolicyEvaluation.where(conversation_id: conversation_id)
              scope = scope.or(message_inference_request_id: request_ids) unless request_ids.empty?
              scope = scope.or(message_inference_response_id: response_ids) unless response_ids.empty?
              scope.order(:evaluated_at, :id).all
            end

            def security_events_for(conversation_id, request_ids, response_ids, tool_call_ids)
              scope = where(conversation_id: conversation_id)
              scope = scope.or(message_inference_request_id: request_ids) unless request_ids.empty?
              scope = scope.or(message_inference_response_id: response_ids) unless response_ids.empty?
              scope = scope.or(tool_call_id: tool_call_ids) unless tool_call_ids.empty?
              scope.order(:detected_at, :id).all
            end
          end
        end
      end
    end
  end
end
