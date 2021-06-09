require 'spec_helper'
Legion::Data::Connection.setup
Legion::Data::Models.load

RSpec.describe Legion::Data::Model::Task do
  after(:all) do
    Legion::Data::Connection.shutdown
  end

  it { should respond_to? :relationship }
  it { should respond_to? :task_log }
  it { should respond_to? :parent }
  it { should respond_to? :children }
  it { should respond_to? :master }
  it { should respond_to? :slave }
  it { should respond_to? :user_owner }
  it { should respond_to? :group_owner }
  it { should be_a Sequel::Model }
end
