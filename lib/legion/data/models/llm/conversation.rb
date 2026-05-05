# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class Conversation < Sequel::Model(:llm_conversations)
          include ModelHelpers

          one_to_many :messages
          one_to_many :message_inference_requests
          one_to_many :conversation_compactions
          one_to_many :policy_evaluations
          one_to_many :security_events

          def security_incident_lineage
            SecurityEvent.lineage_for_conversation(self)
          end
        end
      end
    end
  end
end
