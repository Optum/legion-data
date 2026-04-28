# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 075: add task idempotency' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 75)
  end

  it 'adds idempotency_key to tasks' do
    expect(db.schema(:tasks).map(&:first)).to include(:idempotency_key)
  end

  it 'adds idempotency_expires_at to tasks' do
    expect(db.schema(:tasks).map(&:first)).to include(:idempotency_expires_at)
  end

  it 'indexes idempotency_key' do
    expect(db.indexes(:tasks)).to have_key(:idx_tasks_idempotency_key)
  end

  it 'indexes idempotency_expires_at' do
    expect(db.indexes(:tasks)).to have_key(:idx_tasks_idempotency_expires_at)
  end
end
