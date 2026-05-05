# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class Message < Sequel::Model(:llm_messages)
          include ModelHelpers

          many_to_one :conversation
          many_to_one :parent_message, class: 'Legion::Data::Model::LLM::Message', key: :parent_message_id
          many_to_one :message_inference_request
          many_to_one :message_inference_response
          many_to_one :tool_call

          one_to_many :child_messages, class: 'Legion::Data::Model::LLM::Message', key: :parent_message_id
          one_to_many :triggered_message_inference_requests,
                      class: 'Legion::Data::Model::LLM::MessageInferenceRequest',
                      key:   :latest_message_id
          one_to_many :message_inference_responses,
                      class: 'Legion::Data::Model::LLM::MessageInferenceResponse',
                      key:   :response_message_id
          one_to_many :requested_tool_calls, class: 'Legion::Data::Model::LLM::ToolCall',
                                             key:   :requested_by_message_id
          one_to_many :result_tool_calls, class: 'Legion::Data::Model::LLM::ToolCall',
                                          key:   :result_message_id
          one_to_many :compactions_from, class: 'Legion::Data::Model::LLM::ConversationCompaction',
                                         key:   :replaces_message_from_id
          one_to_many :compactions_to, class: 'Legion::Data::Model::LLM::ConversationCompaction',
                                       key:   :replaces_message_to_id

          class << self
            def incident_flow_from(message_or_id)
              message = message_or_id.is_a?(self) ? message_or_id : self[message_or_id]
              message&.incident_flow
            end
          end

          def incident_flow
            requests = incident_flow_requests
            responses = incident_flow_responses(requests)
            route_attempts = RouteAttempt.where(message_inference_request_id: requests.map(&:id))
                                         .order(:message_inference_request_id, :attempt_no, :id)
                                         .all
            tool_calls = incident_flow_tool_calls(responses)
            tool_call_attempts = ToolCallAttempt.where(tool_call_id: tool_calls.map(&:id))
                                                .order(:tool_call_id, :attempt_no, :id)
                                                .all

            {
              message:            self,
              conversation:       conversation,
              requests:           requests,
              route_attempts:     route_attempts,
              responses:          responses,
              response_messages:  responses.filter_map(&:response_message),
              tool_calls:         tool_calls,
              tool_call_attempts: tool_call_attempts,
              result_messages:    incident_flow_result_messages(responses, tool_calls)
            }
          end

          private

          def incident_flow_requests
            request_ids = []
            request_ids << message_inference_request_id if message_inference_request_id
            request_ids.concat(MessageInferenceRequest.where(latest_message_id: id).select_map(:id))
            if message_inference_response_id && (linked_response = MessageInferenceResponse[message_inference_response_id])
              request_ids << linked_response.message_inference_request_id
            end
            if tool_call_id && (linked_tool_call = ToolCall[tool_call_id])
              request_ids << linked_tool_call.message_inference_response.message_inference_request_id
            end

            MessageInferenceRequest.where(id: request_ids.uniq).order(:id).all
          end

          def incident_flow_responses(requests)
            request_ids = requests.map(&:id)
            response_scope = MessageInferenceResponse.where(message_inference_request_id: request_ids)
            response_scope = response_scope.or(id: message_inference_response_id) if message_inference_response_id
            response_scope.order(:id).all
          end

          def incident_flow_tool_calls(responses)
            response_ids = responses.map(&:id)
            scope = ToolCall.where(message_inference_response_id: response_ids)
            scope = scope.or(requested_by_message_id: id).or(result_message_id: id)
            scope.order(:message_inference_response_id, :tool_call_index, :id).all
          end

          def incident_flow_result_messages(responses, tool_calls)
            message_ids = responses.filter_map(&:response_message_id) + tool_calls.filter_map(&:result_message_id)
            scope = Message.where(id: message_ids.uniq)
            scope = scope.or(tool_call_id: tool_calls.map(&:id)) unless tool_calls.empty?
            scope.order(:seq, :id).all
          end
        end
      end
    end
  end
end
