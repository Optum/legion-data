# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class MessageInferenceRequest < Sequel::Model(:llm_message_inference_requests)
          include ModelHelpers

          many_to_one :conversation
          many_to_one :latest_message, class: 'Legion::Data::Model::LLM::Message', key: :latest_message_id
          one_to_many :message_inference_responses
          one_to_many :route_attempts
          one_to_many :message_inference_metrics
          one_to_many :conversation_compactions, key: :triggered_by_message_inference_request_id
          one_to_many :policy_evaluations
          one_to_many :security_events

          class << self
            def lookup(reference)
              return reference if reference.is_a?(self)

              value = reference.to_s
              scope = where(uuid: value).or(request_ref: value)
              scope = scope.or(id: value.to_i) if value.match?(/\A\d+\z/)
              scope.first
            end

            def audit_lineage_for(reference)
              lookup(reference)&.audit_lineage
            end
          end

          def audit_lineage
            responses = message_inference_responses_dataset.order(:id).all
            response_ids = responses.map(&:id)
            tool_calls = ToolCall.where(message_inference_response_id: response_ids).order(:tool_call_index, :id).all
            tool_call_ids = tool_calls.map(&:id)

            {
              request:            self,
              request_id:         id,
              request_ref:        request_ref,
              conversation:       conversation,
              latest_message:     latest_message,
              caller_principal:   caller_principal,
              caller_identity:    caller_identity,
              route_attempts:     route_attempts_dataset.order(:attempt_no, :id).all,
              responses:          responses,
              response_messages:  responses.filter_map(&:response_message),
              metrics:            message_inference_metrics_dataset.order(:recorded_at, :id).all,
              policy_evaluations: policy_evaluations_dataset.order(:evaluated_at, :id).all,
              security_events:    security_events_dataset.order(:detected_at, :id).all,
              tool_calls:         tool_calls,
              tool_call_attempts: ToolCallAttempt.where(tool_call_id: tool_call_ids).order(:tool_call_id, :attempt_no, :id).all
            }
          end

          def request
            self
          end

          def caller_principal
            return nil unless caller_principal_id && defined?(Legion::Data::Model::Identity::Principal)

            Legion::Data::Model::Identity::Principal.first(id: caller_principal_id)
          end

          def caller_identity
            return nil unless caller_identity_id && defined?(Legion::Data::Model::Identity::Identity)

            Legion::Data::Model::Identity::Identity.first(id: caller_identity_id)
          end
        end
      end
    end
  end
end
