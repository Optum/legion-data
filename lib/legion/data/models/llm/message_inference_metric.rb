# frozen_string_literal: true

require_relative 'model_helpers'

module Legion
  module Data
    module Models
      module LLM
        class MessageInferenceMetric < Sequel::Model(:llm_message_inference_metrics)
          include ModelHelpers

          many_to_one :message_inference_request
          many_to_one :message_inference_response
          one_to_many :context_accounting_events

          class << self
            def finance_usage_by_cost_center_model_day(cost_center: nil, model_key: nil, from: nil, to: nil)
              usage_day = Sequel.function(:date, :recorded_at)
              scope = dataset
              scope = scope.where(cost_center: cost_center) unless cost_center.nil?
              scope = scope.where(model_key: model_key) unless model_key.nil?
              scope = scope.where { recorded_at >= from } unless from.nil?
              scope = scope.where { recorded_at < to } unless to.nil?

              scope
                .select(
                  :cost_center,
                  :model_key,
                  usage_day.as(:usage_day),
                  Sequel.function(:sum, :input_tokens).as(:input_tokens),
                  Sequel.function(:sum, :output_tokens).as(:output_tokens),
                  Sequel.function(:sum, :thinking_tokens).as(:thinking_tokens),
                  Sequel.function(:sum, :total_tokens).as(:total_tokens),
                  Sequel.function(:sum, :cost_usd).as(:cost_usd),
                  Sequel.function(:sum, :latency_ms).as(:latency_ms),
                  Sequel.function(:sum, :wall_clock_ms).as(:wall_clock_ms)
                )
                .group(:cost_center, :model_key, usage_day)
                .order(:cost_center, :model_key, usage_day)
                .map(&:values)
            end
          end
        end
      end
    end
  end
end
