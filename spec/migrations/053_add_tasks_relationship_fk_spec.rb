# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 053: add tasks relationship FK' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 53)
  end

  context 'when adapter is not postgres' do
    it 'skips constraint addition gracefully' do
      skip 'postgres-only migration' if db.adapter_scheme == :postgres
    end
  end

  context 'when adapter is postgres', if: begin
    Legion::Data::Connection.sequel.adapter_scheme == :postgres
  rescue StandardError
    false
  end do
    it 'adds fk_tasks_relationship_id constraint on tasks' do
      constraints = db.fetch(
        "SELECT conname FROM pg_constraint WHERE conname = 'fk_tasks_relationship_id'"
      ).all
      expect(constraints).not_to be_empty
    end
  end

  it 'is idempotent when run twice' do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    expect do
      Sequel::Migrator.run(db, migration_path, target: 53)
    end.not_to raise_error
  end
end
