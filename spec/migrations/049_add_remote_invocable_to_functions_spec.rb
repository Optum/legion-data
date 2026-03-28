# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 049: add remote_invocable to functions' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 49)
  end

  it 'adds remote_invocable column to functions' do
    columns = db.schema(:functions).map(&:first)
    expect(columns).to include(:remote_invocable)
  end

  it 'remote_invocable defaults to true' do
    col = db.schema(:functions).find { |c| c.first == :remote_invocable }
    expect(col.last[:ruby_default]).to eq(true)
  end

  it 'remote_invocable is not nullable' do
    col = db.schema(:functions).find { |c| c.first == :remote_invocable }
    expect(col.last[:allow_null]).to be false
  end

  it 'is idempotent when run twice' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect do
      Sequel::Migrator.run(db, migration_path, target: 49)
    end.not_to raise_error
  end
end
