# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '039_add_audit_archive_manifest migration' do
  let(:db) { Legion::Data::Connection.sequel }

  before do
    migration_path = File.expand_path('../../../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(db, migration_path, target: 39)
  end

  it 'creates audit_archive_manifests table' do
    expect(db.table_exists?(:audit_archive_manifests)).to be true
  end

  it 'has required columns' do
    cols = db.schema(:audit_archive_manifests).map { |c| c[0] }
    expect(cols).to include(:id, :tier, :storage_url, :start_date, :end_date,
                            :entry_count, :checksum, :first_hash, :last_hash,
                            :archived_at)
  end
end
