# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Task < Sequel::Model
        many_to_one :relationship
        one_to_many :task_log
        many_to_one :parent, class: self
        one_to_many :children, key: :parent_id, class: self
        many_to_one :master, class: self
        one_to_many :slave, key: :master_id, class: self
      end
    end
  end
end
