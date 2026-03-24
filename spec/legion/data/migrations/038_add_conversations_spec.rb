# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 038: add conversations' do
  let(:db) { Legion::Data::Connection.sequel }

  before do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(db, migration_path, target: 38)
  end

  it 'creates conversations table' do
    expect(db.table_exists?(:conversations)).to be true
  end

  it 'creates conversation_messages table' do
    expect(db.table_exists?(:conversation_messages)).to be true
  end

  it 'enforces unique (conversation_id, seq)' do
    db[:conversations].insert(id: 'conv_test', created_at: Time.now.utc, updated_at: Time.now.utc)
    db[:conversation_messages].insert(
      conversation_id: 'conv_test', seq: 1, role: 'user', content: 'hello', created_at: Time.now.utc
    )
    expect do
      db[:conversation_messages].insert(
        conversation_id: 'conv_test', seq: 1, role: 'user', content: 'dupe', created_at: Time.now.utc
      )
    end.to raise_error(Sequel::UniqueConstraintViolation)
  end
end
