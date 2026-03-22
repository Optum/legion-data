# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Node < Sequel::Model
        # one_to_many :task_log

        def parsed_metrics
          return nil unless metrics

          Legion::JSON.load(metrics)
        rescue StandardError => e
          Legion::Logging.debug("Node#parsed_metrics JSON parse failed: #{e.message}") if defined?(Legion::Logging)
          nil
        end

        def parsed_hosted_worker_ids
          return [] unless hosted_worker_ids

          Legion::JSON.load(hosted_worker_ids)
        rescue StandardError => e
          Legion::Logging.debug("Node#parsed_hosted_worker_ids JSON parse failed: #{e.message}") if defined?(Legion::Logging)
          []
        end
      end
    end
  end
end
