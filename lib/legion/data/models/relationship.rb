# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Relationship < Sequel::Model
        many_to_one :trigger, class: 'Legion::Data::Model::Function'
        many_to_one :action, class: 'Legion::Data::Model::Function'
        one_to_many :tasks
      end
    end
  end
end
