# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Function < Sequel::Model
        many_to_one :runner
        # one_to_many :trigger_relationships, class: 'Legion::Data::Model::Relationship', key: :trigger_id
        # one_to_many :action_relationships, class: 'Legion::Data::Model::Relationship', key: :action_id
      end
    end
  end
end
