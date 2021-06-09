require 'spec_helper'
# Legion::Data::Connection.setup
Legion::Data::Models.load

RSpec.describe Legion::Data::Model::Extension do
  after(:all) do
    Legion::Data::Connection.shutdown
  end

  it { should respond_to? :runners }
  it { should respond_to? :user_owner }
  it { should respond_to? :group_owner }
  it { should be_a Sequel::Model }
end
