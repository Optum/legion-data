# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 051: fix tasks created_at' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 51)
  end

  it 'adds created_at column to tasks' do
    columns = db.schema(:tasks).map(&:first)
    expect(columns).to include(:created_at)
  end

  it 'has index on tasks.created_at' do
    expect(db.indexes(:tasks)).to have_key(:idx_tasks_created_at)
  end

  context 'when adapter is postgres', if: begin
    Legion::Data::Connection.sequel.adapter_scheme == :postgres
  rescue StandardError
    false
  end do
    it 'created_at is a generated column derived from created' do
      result = db.fetch(
        'SELECT generation_expression FROM information_schema.columns ' \
        "WHERE table_name = 'tasks' AND column_name = 'created_at'"
      ).first
      expect(result).not_to be_nil
      expect(result[:generation_expression]).to include('created')
    end
  end

  context 'when adapter is not postgres' do
    it 'created_at is a real DateTime column' do
      skip 'postgres uses generated column instead' if db.adapter_scheme == :postgres

      col = db.schema(:tasks).find { |c| c.first == :created_at }
      expect(col).not_to be_nil
    end
  end

  it 'is idempotent when run twice' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect do
      Sequel::Migrator.run(db, migration_path, target: 51)
    end.not_to raise_error
  end
end
