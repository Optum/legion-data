# frozen_string_literal: true

require_relative 'function'
module Legion
  module Data
    module Model
      class Runner < Sequel::Model
        one_to_many :functions
        many_to_one :extension

        def chain
          chains_dataset.first
        end

        def chains_dataset
          Legion::Data::Model::Chain.where(id: relationships_dataset.select(:chain_id))
        end

        def task
          task_dataset.all
        end

        def task_dataset
          Legion::Data::Model::Task.where(function_id: functions_dataset.select(:id))
        end

        def relationships_dataset
          function_ids = functions_dataset.select(:id)

          Legion::Data::Model::Relationship
            .where(trigger_id: function_ids)
            .or(action_id: function_ids)
        end
      end
    end
  end
end
