require 'spec_helper'
Legion::Data::Connection.setup
Legion::Data::Models.load

RSpec.describe Legion::Data::Model::Runner do
  after(:all) do
    Legion::Data::Connection.shutdown
  end

  it { should respond_to? :chain }
  it { should respond_to? :task }
  it { should respond_to? :functions }
  it { should respond_to? :extension }
  it { should respond_to? :user_owner }
  it { should respond_to? :group_owner }
  it { should be_a Sequel::Model }
end
