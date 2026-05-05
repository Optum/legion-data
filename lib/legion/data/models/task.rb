# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Task < Sequel::Model
        many_to_one :function
        many_to_one :relationship
        one_to_many :task_log
        one_to_many :task_logs, class: 'Legion::Data::Model::TaskLog'
        many_to_one :parent, class: self
        one_to_many :children, key: :parent_id, class: self
        many_to_one :master, class: self
        one_to_many :slave, key: :master_id, class: self
        one_to_many :slaves, key: :master_id, class: self
        many_to_one :digital_worker, key: :worker_id, primary_key: :worker_id

        def cancelled?
          !cancelled_at.nil?
        end
      end
    end
  end
end
