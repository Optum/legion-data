# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Migration 042: add tenant_id to registry tables' do
  let(:db) { Legion::Data::Connection.sequel }

  before(:all) do
    migration_path = File.expand_path('../../lib/legion/data/migrations', __dir__)
    Sequel::Migrator.run(Legion::Data::Connection.sequel, migration_path, target: 46)
  end

  %i[extensions functions runners nodes settings value_metrics].each do |table|
    describe "#{table} table" do
      it 'has a tenant_id column' do
        expect(db.schema(table).map(&:first)).to include(:tenant_id)
      end

      it 'tenant_id column allows null' do
        col = db.schema(table).find { |c| c.first == :tenant_id }
        expect(col).not_to be_nil
        expect(col.last[:allow_null]).to be true
      end

      it 'has an index on tenant_id' do
        indexes = db.indexes(table)
        index_name = :"idx_#{table}_tenant_id"
        expect(indexes).to have_key(index_name)
      end
    end
  end
end
