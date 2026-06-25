# frozen_string_literal: true

require 'spec_helper'

Legion::Data::Connection.setup unless Legion::Data.connected?
Legion::Data::Migration.migrate(Legion::Data::Connection.sequel, File.expand_path('../../../../lib/legion/data/migrations', __dir__))
Legion::Data::Models.load

RSpec.describe 'LLM model namespace' do
  let(:conversation_model) { Legion::Data::Models::LLM::Conversation }
  let(:message_model) { Legion::Data::Models::LLM::Message }
  let(:request_model) { Legion::Data::Models::LLM::MessageInferenceRequest }
  let(:response_model) { Legion::Data::Models::LLM::MessageInferenceResponse }

  before do
    %i[
      llm_message_inference_responses
      llm_message_inference_requests
      llm_messages
      llm_conversations
    ].each { |table| Legion::Data::Connection.sequel[table].delete }
  end

  it 'creates the conversation to request to response association graph from official constants' do
    conversation = conversation_model.create(principal_id: 101, identity_id: 202, title: 'fleet response')
    message = message_model.create(conversation_id: conversation.id, seq: 1, role: 'user', content: 'hello')
    request = request_model.create(
      conversation_id:      conversation.id,
      latest_message_id:    message.id,
      operation:            'chat',
      request_type:         'chat',
      correlation_id:       'corr-123',
      idempotency_key:      'idem-123',
      request_capture_mode: 'full',
      request_json:         '{"messages":[]}'
    )
    response = response_model.create(
      message_inference_request_id: request.id,
      provider:                     'vllm',
      provider_instance:            'apollo',
      model_key:                    'qwen3.6-27b',
      dispatch_path:                'fleet',
      response_capture_mode:        'full',
      response_json:                '{"content":"hello"}',
      response_thinking_json:       '{"content":"thinking"}'
    )

    expect(conversation.messages).to contain_exactly(message)
    expect(message.triggered_message_inference_requests).to contain_exactly(request)
    expect(request.latest_message).to eq(message)
    expect(request.message_inference_responses).to contain_exactly(response)
    expect(response.message_inference_request).to eq(request)
  end
end
