# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/partition_manager'

RSpec.describe Legion::Data::PartitionManager do
  # ---------------------------------------------------------------------------
  # Shared mock DB
  # ---------------------------------------------------------------------------
  let(:executed_sql) { [] }
  let(:mock_db) do
    db = double('Sequel::Database')
    allow(db).to receive(:run) { |sql| executed_sql << sql }
    allow(db).to receive(:fetch).and_return([])
    db
  end

  before(:each) do
    allow(Legion::Data).to receive(:connection).and_return(mock_db)
  end

  # ---------------------------------------------------------------------------
  # Helper: freeze the adapter response
  # ---------------------------------------------------------------------------
  def with_adapter(adapter)
    allow(Legion::Data::Connection).to receive(:adapter).and_return(adapter)
  end

  # ---------------------------------------------------------------------------
  # 1. Non-postgres guard
  # ---------------------------------------------------------------------------
  describe 'non-postgres guard' do
    %i[sqlite mysql2].each do |adapter|
      context "when adapter is #{adapter}" do
        before { with_adapter(adapter) }

        it 'ensure_partitions returns skipped' do
          result = described_class.ensure_partitions(table: :events)
          expect(result).to eq({ skipped: true, reason: 'not_postgres' })
        end

        it 'drop_old_partitions returns skipped' do
          result = described_class.drop_old_partitions(table: :events)
          expect(result).to eq({ skipped: true, reason: 'not_postgres' })
        end

        it 'list_partitions returns skipped' do
          result = described_class.list_partitions(table: :events)
          expect(result).to eq({ skipped: true, reason: 'not_postgres' })
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # 2 & 3. ensure_partitions: DDL content and idempotency
  # ---------------------------------------------------------------------------
  describe '.ensure_partitions' do
    before { with_adapter(:postgres) }

    # Return empty fetch (partition didn't exist before) for all calls
    before do
      allow(mock_db).to receive(:fetch).and_return([])
    end

    it 'generates CREATE TABLE IF NOT EXISTS DDL for each month' do
      travel_to = Date.new(2025, 11, 15)
      allow(Date).to receive(:today).and_return(travel_to)

      described_class.ensure_partitions(table: :events, months_ahead: 3)

      expect(executed_sql.size).to eq(3)
      expect(executed_sql[0]).to include('CREATE TABLE IF NOT EXISTS events_y2025m11')
      expect(executed_sql[1]).to include('CREATE TABLE IF NOT EXISTS events_y2025m12')
      expect(executed_sql[2]).to include('CREATE TABLE IF NOT EXISTS events_y2026m01')
    end

    it 'uses IF NOT EXISTS (idempotent DDL)' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 6, 1))

      described_class.ensure_partitions(table: :events, months_ahead: 1)

      expect(executed_sql.first).to include('IF NOT EXISTS')
    end

    it 'sets correct FROM/TO boundaries' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 3, 1))

      described_class.ensure_partitions(table: :events, months_ahead: 1)

      ddl = executed_sql.first
      expect(ddl).to include("FROM ('2025-03-01')")
      expect(ddl).to include("TO ('2025-04-01')")
    end

    it 'includes table name in DDL' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 1, 1))

      described_class.ensure_partitions(table: :my_events, months_ahead: 1)

      expect(executed_sql.first).to include('PARTITION OF my_events')
    end

    it 'returns created and existing arrays' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 1, 1))
      result = described_class.ensure_partitions(table: :events, months_ahead: 2)
      expect(result).to have_key(:created)
      expect(result).to have_key(:existing)
      expect((result[:created] + result[:existing]).size).to eq(2)
    end
  end

  # ---------------------------------------------------------------------------
  # 4. Year-boundary month wrapping
  # ---------------------------------------------------------------------------
  describe '.ensure_partitions year-boundary math' do
    before { with_adapter(:postgres) }

    before do
      allow(mock_db).to receive(:fetch).and_return([])
    end

    it 'wraps December -> January correctly' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 12, 1))
      described_class.ensure_partitions(table: :events, months_ahead: 2)

      expect(executed_sql[0]).to include('events_y2025m12')
      expect(executed_sql[1]).to include('events_y2026m01')
    end

    it 'correctly advances across a year boundary for FROM/TO' do
      allow(Date).to receive(:today).and_return(Date.new(2025, 12, 1))
      described_class.ensure_partitions(table: :events, months_ahead: 2)

      dec_ddl = executed_sql[0]
      expect(dec_ddl).to include("FROM ('2025-12-01')")
      expect(dec_ddl).to include("TO ('2026-01-01')")

      jan_ddl = executed_sql[1]
      expect(jan_ddl).to include("FROM ('2026-01-01')")
      expect(jan_ddl).to include("TO ('2026-02-01')")
    end
  end

  # ---------------------------------------------------------------------------
  # 5. drop_old_partitions: only drops outside retention window
  # ---------------------------------------------------------------------------
  describe '.drop_old_partitions' do
    before { with_adapter(:postgres) }

    let(:today) { Date.new(2025, 6, 1) }

    before { allow(Date).to receive(:today).and_return(today) }

    def stub_partitions(names)
      rows = names.map { |n| { name: n } }
      allow(mock_db).to receive(:fetch).and_return(rows)
    end

    it 'drops partitions older than retention window' do
      # 24 months ago from 2025-06: cutoff is 2023-06
      # 2022-01 is older → drop; 2024-01 is within → retain
      stub_partitions(%w[events_y2022m01 events_y2024m01])

      result = described_class.drop_old_partitions(table: :events, retention_months: 24)

      expect(result[:dropped]).to eq(['events_y2022m01'])
      expect(result[:retained]).to eq(['events_y2024m01'])
      expect(executed_sql).to include('DROP TABLE events_y2022m01')
      expect(executed_sql).not_to include('DROP TABLE events_y2024m01')
    end

    it 'drops nothing when all partitions are within retention' do
      stub_partitions(%w[events_y2024m01 events_y2025m01])

      result = described_class.drop_old_partitions(table: :events, retention_months: 24)

      expect(result[:dropped]).to be_empty
      expect(result[:retained].size).to eq(2)
      expect(executed_sql).to be_empty
    end

    it 'handles a partition exactly at the cutoff boundary (not dropped)' do
      # cutoff = 2023-06-01 — a partition named y2023m06 equals cutoff, not older
      stub_partitions(['events_y2023m06'])

      result = described_class.drop_old_partitions(table: :events, retention_months: 24)

      expect(result[:dropped]).to be_empty
      expect(result[:retained]).to eq(['events_y2023m06'])
    end

    it 'skips partitions with unparseable names' do
      stub_partitions(%w[events_custom_name events_y2022m01])

      result = described_class.drop_old_partitions(table: :events, retention_months: 24)

      expect(result[:dropped]).to eq(['events_y2022m01'])
    end
  end

  # ---------------------------------------------------------------------------
  # 7. list_partitions with empty result
  # ---------------------------------------------------------------------------
  describe '.list_partitions with empty result' do
    before { with_adapter(:postgres) }

    it 'returns empty array when no partitions exist' do
      allow(mock_db).to receive(:fetch).and_return([])

      result = described_class.list_partitions(table: :events)
      expect(result).to eq([])
    end
  end

  # ---------------------------------------------------------------------------
  # 8. list_partitions with populated result
  # ---------------------------------------------------------------------------
  describe '.list_partitions with populated result' do
    before { with_adapter(:postgres) }

    it 'returns array of hashes with name, from, to' do
      rows = [
        { name: 'events_y2025m01', bound: "FOR VALUES FROM ('2025-01-01') TO ('2025-02-01')" },
        { name: 'events_y2025m02', bound: "FOR VALUES FROM ('2025-02-01') TO ('2025-03-01')" }
      ]
      allow(mock_db).to receive(:fetch).and_return(rows)

      result = described_class.list_partitions(table: :events)

      expect(result.size).to eq(2)
      expect(result[0]).to eq({ name: 'events_y2025m01', from: '2025-01-01', to: '2025-02-01' })
      expect(result[1]).to eq({ name: 'events_y2025m02', from: '2025-02-01', to: '2025-03-01' })
    end

    it 'handles rows with a nil bound gracefully' do
      rows = [{ name: 'events_y2025m01', bound: nil }]
      allow(mock_db).to receive(:fetch).and_return(rows)

      result = described_class.list_partitions(table: :events)
      expect(result.size).to eq(1)
      expect(result[0][:from]).to be_nil
      expect(result[0][:to]).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # 9. Logging when Legion::Logging is available
  # ---------------------------------------------------------------------------
  describe 'logging when Legion::Logging is present' do
    before { with_adapter(:postgres) }

    before do
      allow(Date).to receive(:today).and_return(Date.new(2025, 1, 1))
    end

    it 'calls Legion::Logging.info for created partitions' do
      # First fetch (before run) returns empty — partition doesn't exist yet.
      # Second fetch (after run) returns the new row — partition was created.
      fetch_calls = 0
      allow(mock_db).to receive(:fetch) do
        fetch_calls += 1
        fetch_calls == 1 ? [] : [{ name: 'events_y2025m01' }]
      end

      logging_double = double('Legion::Logging')
      allow(logging_double).to receive(:info)
      stub_const('Legion::Logging', logging_double)

      described_class.ensure_partitions(table: :events, months_ahead: 1)

      expect(logging_double).to have_received(:info).at_least(:once)
    end
  end

  # ---------------------------------------------------------------------------
  # 10. Graceful when Legion::Logging is absent
  # ---------------------------------------------------------------------------
  describe 'graceful when Legion::Logging is absent' do
    before { with_adapter(:postgres) }

    before do
      allow(Date).to receive(:today).and_return(Date.new(2025, 1, 1))
      allow(mock_db).to receive(:fetch).and_return([])
    end

    it 'does not raise when Legion::Logging is not defined' do
      # Hide Legion::Logging from the constant lookup without actually removing it
      allow(described_class).to receive(:logging?).and_return(false)

      expect { described_class.ensure_partitions(table: :events, months_ahead: 1) }.not_to raise_error
      expect { described_class.drop_old_partitions(table: :events, retention_months: 24) }.not_to raise_error
      expect { described_class.list_partitions(table: :events) }.not_to raise_error
    end
  end
end
