# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Model
      module LLM
        class ConversationCompaction < Sequel::Model(:llm_conversation_compactions)
          include ModelHelpers

          many_to_one :conversation
          many_to_one :triggered_by_message_inference_request,
                      class: 'Legion::Data::Model::LLM::MessageInferenceRequest',
                      key:   :triggered_by_message_inference_request_id
          many_to_one :replaces_message_from, class: 'Legion::Data::Model::LLM::Message', key: :replaces_message_from_id
          many_to_one :replaces_message_to, class: 'Legion::Data::Model::LLM::Message', key: :replaces_message_to_id
        end
      end
    end
  end
end
