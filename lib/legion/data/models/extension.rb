# frozen_string_literal: true

module Legion
  module Data
    module Model
      class Extension < Sequel::Model
        one_to_many :runners
      end
    end
  end
end
