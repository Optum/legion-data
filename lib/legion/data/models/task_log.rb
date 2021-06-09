# frozen_string_literal: true

module Legion
  module Data
    module Model
      class TaskLog < Sequel::Model
        many_to_one :task
        many_to_one :node
      end
    end
  end
end
