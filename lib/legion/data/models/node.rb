# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Node < Sequel::Model
        # one_to_many :task_log

        def parsed_metrics
          return nil unless metrics

          Legion::JSON.load(metrics)
        rescue StandardError
          nil
        end

        def parsed_hosted_worker_ids
          return [] unless hosted_worker_ids

          Legion::JSON.load(hosted_worker_ids)
        rescue StandardError
          []
        end
      end
    end
  end
end
