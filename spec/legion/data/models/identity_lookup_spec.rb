# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'

RSpec.describe 'identity model lookups' do
  let(:suffix) { SecureRandom.hex(4) }
  let(:provider_uuid) { SecureRandom.uuid }
  let(:principal_uuid) { SecureRandom.uuid }
  let(:identity_uuid) { SecureRandom.uuid }
  let(:group_uuid) { SecureRandom.uuid }

  let!(:provider) do
    Legion::Data::Model::Identity::Provider.create(
      uuid:          provider_uuid,
      name:          "lookup-provider-#{suffix}",
      provider_type: 'authenticate',
      facing:        'both'
    )
  end

  let!(:principal) do
    Legion::Data::Model::Identity::Principal.create(
      uuid:           principal_uuid,
      canonical_name: "lookup-principal-#{suffix}",
      kind:           'human',
      employee_key:   "employee-#{suffix}"
    )
  end

  let!(:identity) do
    Legion::Data::Model::Identity::Identity.create(
      uuid:                  identity_uuid,
      principal_id:          principal.id,
      provider_id:           provider.id,
      provider_identity_key: "provider-identity-#{suffix}"
    )
  end

  let!(:group) do
    Legion::Data::Model::Identity::Group.create(
      uuid:   group_uuid,
      name:   "lookup-group-#{suffix}",
      source: 'manual'
    )
  end

  it 'looks up providers by id, uuid, and name' do
    expect(Legion::Data::Model::Identity::Provider.lookup(provider.id)).to eq(provider)
    expect(Legion::Data::Model::Identity::Provider.lookup(provider_uuid)).to eq(provider)
    expect(Legion::Data::Model::Identity::Provider.lookup(provider.name)).to eq(provider)
  end

  it 'looks up principals by id, uuid, canonical name, and employee key' do
    expect(Legion::Data::Model::Identity::Principal.lookup(principal.id)).to eq(principal)
    expect(Legion::Data::Model::Identity::Principal.lookup(principal_uuid)).to eq(principal)
    expect(Legion::Data::Model::Identity::Principal.lookup(principal.canonical_name)).to eq(principal)
    expect(Legion::Data::Model::Identity::Principal.lookup(principal.employee_key)).to eq(principal)
  end

  it 'looks up identities by id, uuid, and provider identity key' do
    expect(Legion::Data::Model::Identity::Identity.lookup(identity.id)).to eq(identity)
    expect(Legion::Data::Model::Identity::Identity.lookup(identity_uuid)).to eq(identity)
    expect(Legion::Data::Model::Identity::Identity.lookup(identity.provider_identity_key)).to eq(identity)
  end

  it 'looks up groups by id, uuid, and name' do
    expect(Legion::Data::Model::Identity::Group.lookup(group.id)).to eq(group)
    expect(Legion::Data::Model::Identity::Group.lookup(group_uuid)).to eq(group)
    expect(Legion::Data::Model::Identity::Group.lookup(group.name)).to eq(group)
  end
end
