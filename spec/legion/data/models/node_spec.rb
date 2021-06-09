require 'spec_helper'
Legion::Data::Connection.setup
Legion::Data::Models.load

RSpec.describe Legion::Data::Model::Node do
  after(:all) do
    Legion::Data::Connection.shutdown
  end

  it { should respond_to? :environment }
  it { should respond_to? :dataceter }
  it { should respond_to? :task_log }
  it { should be_a Sequel::Model }
end
