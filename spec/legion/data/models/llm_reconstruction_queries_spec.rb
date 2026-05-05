# frozen_string_literal: true

require 'spec_helper'

Legion::Data::Connection.setup unless Legion::Data.connected?
Legion::Data::Migration.migrate(Legion::Data::Connection.sequel, File.expand_path('../../../../lib/legion/data/migrations', __dir__))
Legion::Data::Models.load

RSpec.describe 'LLM reconstruction query helpers' do
  let(:conversation_model) { Legion::Data::Model::LLM::Conversation }
  let(:message_model) { Legion::Data::Model::LLM::Message }
  let(:request_model) { Legion::Data::Model::LLM::MessageInferenceRequest }
  let(:response_model) { Legion::Data::Model::LLM::MessageInferenceResponse }
  let(:route_attempt_model) { Legion::Data::Model::LLM::RouteAttempt }
  let(:metric_model) { Legion::Data::Model::LLM::MessageInferenceMetric }
  let(:tool_call_model) { Legion::Data::Model::LLM::ToolCall }
  let(:tool_call_attempt_model) { Legion::Data::Model::LLM::ToolCallAttempt }
  let(:policy_evaluation_model) { Legion::Data::Model::LLM::PolicyEvaluation }
  let(:security_event_model) { Legion::Data::Model::LLM::SecurityEvent }

  before do
    clear_llm_tables
  end

  after(:all) do
    Legion::Data::Connection.shutdown
  end

  it 'reconstructs audit lineage by request_ref and internal id' do
    fixture = create_llm_lifecycle

    by_ref = request_model.audit_lineage_for('req-123')
    by_id = request_model.audit_lineage_for(fixture[:request].id)

    expect(by_ref[:request]).to eq(fixture[:request])
    expect(by_ref[:request_ref]).to eq('req-123')
    expect(by_ref[:conversation]).to eq(fixture[:conversation])
    expect(by_ref[:latest_message]).to eq(fixture[:user_message])
    expect(by_ref[:responses]).to contain_exactly(fixture[:response])
    expect(by_ref[:route_attempts].map(&:status)).to eq(%w[timeout success])
    expect(by_ref[:tool_calls]).to contain_exactly(fixture[:tool_call])
    expect(by_ref[:tool_call_attempts]).to contain_exactly(fixture[:failed_tool_attempt], fixture[:successful_tool_attempt])
    expect(by_id[:request]).to eq(fixture[:request])
  end

  it 'aggregates finance usage by cost center, model, and recorded day from inference metrics' do
    create_llm_lifecycle
    second = create_llm_lifecycle(request_ref: 'req-456', cost_center: 'finance-ops', model_key: 'gpt-4.1',
                                  recorded_at: Time.utc(2026, 5, 5, 3, 0, 0), cost_usd: 0.75)
    metric_model.create(
      message_inference_request_id:  second[:request].id,
      message_inference_response_id: second[:response].id,
      provider:                      'openai',
      model_key:                     'gpt-4.1',
      tier:                          'standard',
      input_tokens:                  10,
      output_tokens:                 20,
      thinking_tokens:               5,
      total_tokens:                  35,
      latency_ms:                    50,
      wall_clock_ms:                 60,
      cost_usd:                      0.25,
      currency:                      'USD',
      cost_center:                   'finance-ops',
      budget_key:                    'budget-a',
      recorded_at:                   Time.utc(2026, 5, 5, 8, 0, 0)
    )

    rollups = metric_model.finance_usage_by_cost_center_model_day

    finance_rollup = rollups.find do |row|
      row[:cost_center] == 'finance-ops' && row[:model_key] == 'gpt-4.1' && row[:usage_day].to_s == '2026-05-05'
    end
    expect(finance_rollup[:input_tokens]).to eq(20)
    expect(finance_rollup[:output_tokens]).to eq(40)
    expect(finance_rollup[:thinking_tokens]).to eq(10)
    expect(finance_rollup[:total_tokens]).to eq(70)
    expect(finance_rollup[:cost_usd].to_f).to eq(1.0)
  end

  it 'reconstructs security incident lineage for a conversation' do
    fixture = create_llm_lifecycle

    lineage = security_event_model.lineage_for_conversation(fixture[:conversation])

    expect(lineage[:conversation]).to eq(fixture[:conversation])
    expect(lineage[:messages]).to include(fixture[:user_message], fixture[:assistant_message], fixture[:tool_result_message])
    expect(lineage[:requests]).to contain_exactly(fixture[:request])
    expect(lineage[:route_attempts].map(&:failure_reason)).to include('runner timeout')
    expect(lineage[:request_payload_hashes]).to contain_exactly('request-hash')
    expect(lineage[:response_payload_hashes]).to contain_exactly('response-hash')
    expect(lineage[:policy_evaluations]).to contain_exactly(fixture[:policy_evaluation])
    expect(lineage[:security_events]).to contain_exactly(fixture[:security_event])
    expect(lineage[:tool_calls]).to contain_exactly(fixture[:tool_call])
    expect(lineage[:tool_call_attempts]).to contain_exactly(fixture[:failed_tool_attempt], fixture[:successful_tool_attempt])
  end

  it 'reconstructs incident flow from message to request, response, tool calls, and attempts' do
    fixture = create_llm_lifecycle

    flow = fixture[:user_message].incident_flow

    expect(flow[:message]).to eq(fixture[:user_message])
    expect(flow[:conversation]).to eq(fixture[:conversation])
    expect(flow[:requests]).to contain_exactly(fixture[:request])
    expect(flow[:responses]).to contain_exactly(fixture[:response])
    expect(flow[:response_messages]).to contain_exactly(fixture[:assistant_message])
    expect(flow[:tool_calls]).to contain_exactly(fixture[:tool_call])
    expect(flow[:tool_call_attempts]).to contain_exactly(fixture[:failed_tool_attempt], fixture[:successful_tool_attempt])
    expect(flow[:result_messages]).to include(fixture[:assistant_message], fixture[:tool_result_message])
  end

  def clear_llm_tables
    %i[
      llm_security_events
      llm_policy_evaluations
      llm_tool_call_attempts
      llm_tool_calls
      llm_message_inference_metrics
      llm_route_attempts
      llm_message_inference_responses
      llm_message_inference_requests
      llm_messages
      llm_conversations
    ].each { |table| Legion::Data::Connection.sequel[table].delete }
  end

  def create_llm_lifecycle(request_ref: 'req-123', cost_center: 'finance-ops', model_key: 'gpt-4.1',
                           recorded_at: Time.utc(2026, 5, 4, 12, 0, 0), cost_usd: 0.42)
    conversation = create_fixture_conversation(recorded_at)
    user_message = create_fixture_user_message(conversation)
    request = create_fixture_request(conversation, user_message, request_ref, cost_center, recorded_at)
    response = create_fixture_response(request, model_key, recorded_at)
    assistant_message = create_fixture_assistant_message(conversation, request, response)
    route_attempts_for(request, response, model_key, recorded_at)
    metric_for(request, response, model_key, cost_center, recorded_at, cost_usd)
    tool_fixture = create_tool_fixture(conversation, request, response, assistant_message, recorded_at)
    policy_evaluation = create_policy_evaluation(conversation, request, response, recorded_at)
    security_event = create_security_event(conversation, request, response, tool_fixture, policy_evaluation, recorded_at)

    {
      conversation:            conversation,
      user_message:            user_message,
      request:                 request,
      response:                response,
      assistant_message:       assistant_message,
      tool_call:               tool_fixture.fetch(:tool_call),
      failed_tool_attempt:     tool_fixture.fetch(:failed_tool_attempt),
      successful_tool_attempt: tool_fixture.fetch(:successful_tool_attempt),
      tool_result_message:     tool_fixture.fetch(:tool_result_message),
      policy_evaluation:       policy_evaluation,
      security_event:          security_event
    }
  end

  def create_fixture_conversation(recorded_at)
    conversation_model.create(principal_id: 101, identity_id: 202, title: 'incident review',
                              classification_level: 'internal', recorded_at: recorded_at)
  end

  def create_fixture_user_message(conversation)
    message_model.create(conversation_id: conversation.id, seq: 1, role: 'user',
                         content: 'please fetch account details')
  end

  def create_fixture_request(conversation, user_message, request_ref, cost_center, recorded_at)
    request_model.create(conversation_id: conversation.id, latest_message_id: user_message.id,
                         caller_principal_id: 101, caller_identity_id: 202,
                         runtime_caller_type: 'user', request_ref: request_ref,
                         correlation_ref: 'corr-123', exchange_ref: 'exchange-123',
                         status: 'responded', cost_center: cost_center,
                         budget_key: 'budget-a', requested_at: recorded_at,
                         request_content_hash: 'request-hash')
  end

  def create_fixture_response(request, model_key, recorded_at)
    response_model.create(message_inference_request_id: request.id, provider: 'openai',
                          model_key: model_key, tier: 'standard', status: 'success',
                          finish_reason: 'tool_calls', response_content_hash: 'response-hash',
                          responded_at: recorded_at + 1)
  end

  def create_fixture_assistant_message(conversation, request, response)
    message = message_model.create(conversation_id: conversation.id,
                                   message_inference_request_id: request.id,
                                   message_inference_response_id: response.id,
                                   seq: 2, role: 'assistant', content: 'calling tool')
    response.update(response_message_id: message.id)
    message
  end

  def route_attempts_for(request, response, model_key, recorded_at)
    route_attempt_model.create(message_inference_request_id: request.id, attempt_no: 1, provider: 'vllm',
                               model_key: model_key, tier: 'standard', route_target: 'runner-a',
                               status: 'timeout', failure_reason: 'runner timeout', latency_ms: 1_000,
                               started_at: recorded_at, ended_at: recorded_at + 1)
    route_attempt_model.create(message_inference_request_id: request.id, message_inference_response_id: response.id,
                               attempt_no: 2, provider: 'openai', model_key: model_key, tier: 'standard',
                               route_target: 'provider-c', status: 'success', latency_ms: 500,
                               started_at: recorded_at + 1, ended_at: recorded_at + 2)
  end

  def metric_for(request, response, model_key, cost_center, recorded_at, cost_usd)
    metric_model.create(message_inference_request_id: request.id, message_inference_response_id: response.id,
                        provider: 'openai', model_key: model_key, tier: 'standard',
                        input_tokens: 10, output_tokens: 20, thinking_tokens: 5, total_tokens: 35,
                        latency_ms: 500, wall_clock_ms: 550, cost_usd: cost_usd, currency: 'USD',
                        cost_center: cost_center, budget_key: 'budget-a', recorded_at: recorded_at)
  end

  def create_tool_fixture(conversation, request, response, assistant_message, recorded_at)
    tool_call = create_tool_call(response, assistant_message, recorded_at)
    failed_tool_attempt = create_failed_tool_attempt(tool_call, recorded_at)
    successful_tool_attempt = create_successful_tool_attempt(tool_call, recorded_at)
    tool_result_message = create_tool_result_message(conversation, request, tool_call)
    tool_call.update(result_message_id: tool_result_message.id)

    {
      tool_call:               tool_call,
      failed_tool_attempt:     failed_tool_attempt,
      successful_tool_attempt: successful_tool_attempt,
      tool_result_message:     tool_result_message
    }
  end

  def create_tool_call(response, assistant_message, recorded_at)
    tool_call_model.create(message_inference_response_id: response.id,
                           requested_by_message_id: assistant_message.id,
                           tool_call_index: 0, provider_tool_call_ref: 'tooluse-123',
                           tool_name: 'fetch_account', tool_source_type: 'mcp',
                           tool_source_server: 'accounts', status: 'succeeded',
                           requested_at: recorded_at + 2, completed_at: recorded_at + 4)
  end

  def create_failed_tool_attempt(tool_call, recorded_at)
    tool_call_attempt_model.create(tool_call_id: tool_call.id, attempt_no: 1,
                                   runner_ref: 'runner-a', status: 'failed',
                                   error_category: 'network', error_code: 'timeout',
                                   error_message: 'timed out', duration_ms: 100,
                                   arguments_ref: 'args-hash', started_at: recorded_at + 2,
                                   ended_at: recorded_at + 3)
  end

  def create_successful_tool_attempt(tool_call, recorded_at)
    tool_call_attempt_model.create(tool_call_id: tool_call.id, attempt_no: 2,
                                   runner_ref: 'runner-b', status: 'succeeded',
                                   duration_ms: 75, arguments_ref: 'args-hash',
                                   result_ref: 'result-hash',
                                   started_at: recorded_at + 3,
                                   ended_at: recorded_at + 4)
  end

  def create_tool_result_message(conversation, request, tool_call)
    message_model.create(conversation_id: conversation.id,
                         message_inference_request_id: request.id,
                         tool_call_id: tool_call.id, seq: 3, role: 'tool',
                         content: 'account details')
  end

  def create_policy_evaluation(conversation, request, response, recorded_at)
    policy_evaluation_model.create(conversation_id: conversation.id,
                                   message_inference_request_id: request.id,
                                   message_inference_response_id: response.id,
                                   policy_key: 'phi-redaction', policy_version: '1',
                                   evaluation_type: 'classification', decision: 'allow',
                                   enforcement_action: 'audit', classification_level: 'internal',
                                   contains_phi: true, contains_pii: true,
                                   reason_code: 'allowed-with-audit',
                                   evaluated_at: recorded_at + 1)
  end

  def create_security_event(conversation, request, response, tool_fixture, policy_evaluation, recorded_at)
    security_event_model.create(conversation_id: conversation.id,
                                message_inference_request_id: request.id,
                                message_inference_response_id: response.id,
                                tool_call_id: tool_fixture.fetch(:tool_call).id,
                                tool_call_attempt_id: tool_fixture.fetch(:failed_tool_attempt).id,
                                policy_evaluation_id: policy_evaluation.id,
                                event_type: 'tool_retry_after_timeout',
                                severity: 'warn', status: 'resolved',
                                description: 'tool retry succeeded',
                                detected_at: recorded_at + 3)
  end
end
