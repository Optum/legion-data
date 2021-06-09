require 'spec_helper'

RSpec.describe Legion::Data::Migration do
  after(:each) do
    Legion::Data::Connection.shutdown
  end

  it 'can migrate' do
    expect { Legion::Data::Migration.migrate }.not_to raise_exception
    expect(Legion::Settings[:data][:migrations][:version]).to be_a Integer
    expect(Legion::Settings[:data][:migrations][:ran]).to eq true
  end

  it 'can go up and down' do
    Legion::Data::Migration.migrate
    # expect{Legion::Data::Migration.migrate(target: 0)}.not_to raise_exception
    # expect{Legion::Data::Migration.migrate}.not_to raise_exception
  end
end
