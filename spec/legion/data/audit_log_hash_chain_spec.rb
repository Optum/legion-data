# frozen_string_literal: true

require 'spec_helper'
require 'legion/data/audit_log_hash_chain'

RSpec.describe Legion::Data::AuditLogHashChain do
  let(:created_at) { Time.utc(2026, 4, 27, 12, 0, 0) }
  let(:record) do
    {
      id:            1,
      principal_id:  'worker-1',
      action:        'execute',
      resource:      'runner#call',
      source:        'amqp',
      status:        'success',
      detail:        '{"task_id":1}',
      created_at:    created_at,
      previous_hash: described_class::GENESIS_HASH
    }
  end

  it 'computes deterministic canonical hashes' do
    expect(described_class.compute_hash(record)).to eq(described_class.compute_hash(record.dup))
    expect(described_class.compute_hash(record)).to match(/\A[0-9a-f]{64}\z/)
  end

  it 'verifies a valid chain' do
    first = record.merge(record_hash: described_class.compute_hash(record))
    second_base = record.merge(id: 2, action: 'finish', previous_hash: first[:record_hash])
    second = second_base.merge(record_hash: described_class.compute_hash(second_base))

    expect(described_class.verify([first, second])).to eq({ valid: true, length: 2 })
  end

  it 'detects parent mismatch' do
    bad = record.merge(previous_hash: 'a' * 64, record_hash: 'b' * 64)
    result = described_class.verify([bad])

    expect(result[:valid]).to be false
    expect(result[:reason]).to eq(:parent_mismatch)
  end

  it 'detects hash mismatch' do
    bad = record.merge(record_hash: 'b' * 64)
    result = described_class.verify([bad])

    expect(result[:valid]).to be false
    expect(result[:reason]).to eq(:hash_mismatch)
  end
end
