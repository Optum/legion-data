require 'spec_helper'
Legion::Data::Connection.setup
Legion::Data::Models.load

RSpec.describe Legion::Data::Model::Setting do
  after(:all) do
    Legion::Data::Connection.shutdown
  end

  it { should be_a Sequel::Model }
end
