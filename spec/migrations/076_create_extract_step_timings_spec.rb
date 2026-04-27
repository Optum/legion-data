# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 076: create extract step timings' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 76)
  end

  it 'creates extract_step_timings' do
    expect(db.table_exists?(:extract_step_timings)).to be true
  end

  it 'has timing metadata columns' do
    columns = db.schema(:extract_step_timings).map(&:first)
    expect(columns).to include(:extract_id, :name, :start_time, :end_time, :status, :error, :duration_ms)
  end

  it 'indexes extract_id' do
    expect(db.indexes(:extract_step_timings)).to have_key(:idx_extract_step_timings_extract_id)
  end
end
