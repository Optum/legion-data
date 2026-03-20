# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 030: add_approval_queue' do
  let(:db) { Legion::Data::Connection.sequel }

  before do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(db, migration_path, target: 30)
  end

  it 'creates the approval_queue table' do
    expect(db.table_exists?(:approval_queue)).to be true
  end

  it 'has all required columns' do
    columns = db.schema(:approval_queue).map(&:first)
    expect(columns).to include(:id, :approval_type, :payload, :requester_id,
                               :status, :reviewer_id, :reviewed_at, :created_at, :tenant_id)
  end

  it 'defaults status to pending' do
    db[:approval_queue].insert(approval_type: 'test', requester_id: 'user-1', created_at: Time.now.utc)
    record = db[:approval_queue].first
    expect(record[:status]).to eq('pending')
  end
end
