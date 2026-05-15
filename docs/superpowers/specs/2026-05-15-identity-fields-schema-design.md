# Identity Fields Schema Design

**Date**: 2026-05-15
**Repo**: legion-data
**Status**: Approved — pending implementation

---

## Problem

Apollo ingested Teams conversation observations from one user's private 1:1 messages. Because apollo_entries had no identity ownership or access scope, GAIA's knowledge retrieval phase (phase 4) semantically matched and injected those observations into a completely different user's conversation context.

The same vector exists across the entire LLM lifecycle: llm_messages, llm_message_inference_requests, llm_tool_records, and related tables store conversation content with no identity link, making any future RAG or context injection over that history equally vulnerable to cross-user leakage.

This design establishes the schema foundation to prevent this. It does not implement access enforcement — that is follow-on work in legion-apollo, lex-apollo, and legion-gaia.

---

## Common Fields Standard

All new tables in legion-data follow this convention. This design retrofits the standard onto existing tables that lack it.

### Required

| Column | Type | Purpose |
|--------|------|---------|
| `id` | `BIGSERIAL PRIMARY KEY` | Internal join key — never exposed externally |
| `identity_principal_id` | `INTEGER` FK → `identity_principals.id` | The provider-agnostic person who caused this row |
| `identity_id` | `INTEGER` FK → `identities.id` | The specific provider credential active at the time |
| `identity_canonical_name` | `VARCHAR(255)` | Denormalized snapshot for fast filtering without joins. Point-in-time copy — may become stale. Use FK join for authoritative lookups. |
| `created_at` | `TIMESTAMPTZ` | Row creation time |
| `updated_at` | `TIMESTAMPTZ` | Last modification time |

### Identity model note

`identity_principals` is the provider-agnostic person (the "who"). `identities` is the provider-bound credential (Entra, Kerberos, etc — the "how they authenticated"). A principal has many identities. This means access checks must allow either path: a match on `identity_principal_id` OR a match on `identity_id` resolves to the same principal. If Entra is down but Kerberos is resolved, the system still grants access to that principal's private entries.

### Existing columns are never renamed or removed

Columns like `agent_id`, `source_agent`, `submitted_by`, `actor`, `caller_identity`, `principal_id` on pre-existing tables are historical record and intentionally left as-is. New identity columns are purely additive alongside them.

---

## Scope

All changes land in a single legion-data PR. Migrations 100–124 plus model association fixes.

Downstream enforcement (legion-apollo, lex-apollo, legion-gaia, lex-knowledge) is follow-on work documented at the end of this spec.

---

## Apollo Tables

### PK Restructure (migrations 100–104)

Four apollo tables currently use UUID as their primary key. This conflicts with the integer PK standard and makes FK joins from child tables expensive. `apollo_operations` already has a BIGSERIAL integer PK and is excluded from this block.

**Migration order**: `apollo_entries` must be restructured before `apollo_access_log` and `apollo_relations`, because both have FK constraints pointing at `apollo_entries.id` (UUID).

| # | Migration | What |
|---|-----------|------|
| 100 | `apollo_entries_pk_swap` | Add `uuid VARCHAR(36)` (copy from `id`), drop FK constraints on child tables that reference `apollo_entries.id`, drop UUID PK, add BIGSERIAL `id` PK, add UNIQUE constraint on `uuid` |
| 101 | `apollo_access_log_pk_swap` | Add `uuid`, swap to BIGSERIAL PK. Add `apollo_entry_id INTEGER` FK → `apollo_entries(id)`, backfill via UUID join against `apollo_entries.uuid`. Leave existing `entry_id` UUID column as historical (no FK). |
| 102 | `apollo_relations_pk_swap` | Add `uuid`, swap to BIGSERIAL PK. Add `from_apollo_entry_id INTEGER` and `to_apollo_entry_id INTEGER` FKs, backfill via UUID join. Leave `from_entry_id`/`to_entry_id` UUID columns as historical. |
| 103 | `apollo_expertise_pk_swap` | Add `uuid`, swap to BIGSERIAL PK. No child FKs to rebuild. |
| 104 | `apollo_entries_archive_pk_swap` | Add `uuid`, swap to BIGSERIAL PK. |

### Identity Columns (migrations 105–111)

All three identity columns added to every apollo table. All nullable — existing rows remain valid with NULLs. Indexes on `identity_principal_id` and `identity_canonical_name` for fast filtering.

Migration 105 also adds `access_scope` to `apollo_entries` (see Access Scope section below).

| # | Migration | Table |
|---|-----------|-------|
| 105 | `add_identity_to_apollo_entries` | `apollo_entries` |
| 106 | `add_identity_to_apollo_access_log` | `apollo_access_log` |
| 107 | `add_identity_to_apollo_relations` | `apollo_relations` |
| 108 | `add_identity_to_apollo_expertise` | `apollo_expertise` |
| 109 | `rename_principal_id_on_apollo_operations` | Rename `principal_id` → `identity_canonical_name` only. Separate migration because rename + add in one transaction fails. |
| 110 | `add_identity_to_apollo_operations` | Add `identity_principal_id` + `identity_id` to `apollo_operations` |
| 111 | `add_identity_to_apollo_entries_archive` | `apollo_entries_archive` — also adds `access_scope` |

---

## Access Scope (apollo_entries + apollo_entries_archive)

Added in migrations 105 and 111.

```sql
access_scope VARCHAR(32) NOT NULL DEFAULT 'global'
```

| Value | Who can retrieve |
|-------|-----------------|
| `global` | Any authenticated principal |
| `team` | Principals sharing a group membership with the submitter |
| `private` | Only the submitting principal |

Default is `global` so all existing entries remain accessible — no backfill required.

### RAG query shape for private scope enforcement

```sql
SELECT * FROM apollo_entries
WHERE (
  access_scope = 'global'
  OR (
    access_scope = 'private'
    AND (
      identity_principal_id = :requesting_principal_id
      OR identity_id IN (
        SELECT id FROM identities
        WHERE principal_id = :requesting_principal_id
      )
    )
  )
  OR (
    access_scope = 'team'
    AND identity_principal_id IN (
      SELECT principal_id FROM identity_group_memberships
      WHERE group_id IN (
        SELECT group_id FROM identity_group_memberships
        WHERE principal_id = :requesting_principal_id
      )
    )
  )
)
AND status IN ('confirmed', 'candidate')
AND confidence >= :min_confidence
ORDER BY embedding <=> :query_embedding
LIMIT :limit
```

The calling code always resolves to a `requesting_principal_id` from `identity_principals` before querying — it never passes a raw credential. This keeps the query provider-agnostic and allows any authenticated credential (Entra, Kerberos, etc.) to satisfy a private-scope check as long as it resolves to the owning principal.

Source channel drives `access_scope` at ingest time (follow-on work in lex-apollo):
- Teams 1:1 chat → `private`
- Teams channel messages → `team` or `global` depending on channel config
- Document corpus via lex-knowledge → `global`

---

## LLM Tables (migrations 112–122)

Same three columns added to every active LLM table. All nullable. All PostgreSQL-only (guarded in migration with `next unless adapter_scheme == :postgres` where applicable).

| # | Migration | Table | Notes |
|---|-----------|-------|-------|
| 112 | `add_identity_to_llm_messages` | `llm_messages` | |
| 113 | `add_identity_to_llm_message_inference_responses` | `llm_message_inference_responses` | |
| 114 | `add_identity_to_llm_message_inference_metrics` | `llm_message_inference_metrics` | |
| 115 | `add_identity_to_llm_policy_evaluations` | `llm_policy_evaluations` | already has `contains_phi`/`contains_pii` |
| 116 | `add_identity_to_llm_route_attempts` | `llm_route_attempts` | |
| 117 | `add_identity_to_llm_security_events` | `llm_security_events` | |
| 118 | `add_identity_to_llm_tool_calls` | `llm_tool_calls` | |
| 119 | `add_identity_to_llm_tool_call_attempts` | `llm_tool_call_attempts` | |
| 120 | `add_identity_to_llm_registry_events` | `llm_registry_events` | system events — principal = the booting agent |
| 121 | `add_identity_to_llm_registry_availability_records` | `llm_registry_availability_records` | same — shadow AI audit trail |
| 122 | `add_identity_to_llm_tool_records` | `llm_tool_records` | has `caller_identity` text + `agent_id` text as historical; new columns are additive |

`llm_conversations` already has `principal_id` (int) and `identity_id` (int). Rename to standard names is deferred — it is a breaking change for active writers and warrants its own PR.

`llm_message_inference_requests` already has `caller_principal_id` and `caller_identity_id`. Same deferral.

---

## Memory Tables (migrations 123–124)

Shared DB only. Local SQLite versions in lex-agentic-memory are out of scope for this PR.

| # | Migration | Table |
|---|-----------|-------|
| 123 | `add_identity_to_memory_traces` | `memory_traces` |
| 124 | `add_identity_to_memory_associations` | `memory_associations` |

---

## Model Association Fixes

### Identity associations (added to every model that gains identity columns)

The following two associations are added to every model below:

```ruby
many_to_one :identity_principal,
            class: 'Legion::Data::Model::Identity::Principal',
            key:   :identity_principal_id

many_to_one :identity,
            class: 'Legion::Data::Model::Identity::Identity',
            key:   :identity_id
```

### Apollo — namespaced models (`lib/legion/data/models/apollo/*.rb`)

**`Apollo::Entry`** — add identity associations + update reverse access_log association to use new integer FK:

```ruby
one_to_many :access_logs,
            class: 'Legion::Data::Model::Apollo::AccessLog',
            key:   :apollo_entry_id
# + identity associations above
```

**`Apollo::AccessLog`** — replace UUID-based entry association with integer FK; add identity associations:

```ruby
many_to_one :apollo_entry,
            class: 'Legion::Data::Model::Apollo::Entry',
            key:   :apollo_entry_id
# + identity associations above
```

**`Apollo::Relation`** — replace UUID FK columns with integer FK columns; add identity associations:

```ruby
many_to_one :from_entry,
            class: 'Legion::Data::Model::Apollo::Entry',
            key:   :from_apollo_entry_id

many_to_one :to_entry,
            class: 'Legion::Data::Model::Apollo::Entry',
            key:   :to_apollo_entry_id
# + identity associations above
```

**`Apollo::Expertise`** — add identity associations only.

**`Apollo::Operation`** — add identity associations only.

### Apollo — flat legacy models (`lib/legion/data/models/apollo_*.rb`)

The flat models (`ApolloEntry`, `ApolloAccessLog`, `ApolloRelation`, `ApolloExpertise`) mirror the namespaced ones and must receive the same association updates:

- `ApolloEntry` — update `one_to_many :access_logs` to use `apollo_entry_id`; add identity associations
- `ApolloAccessLog` — add `many_to_one :apollo_entry` via `apollo_entry_id`; add identity associations
- `ApolloRelation` — update `from_entry`/`to_entry` to use integer FK columns; add identity associations
- `ApolloExpertise` — add identity associations

### LLM — namespaced models (`lib/legion/data/models/llm/*.rb`)

Add identity associations to each model that gains columns in migrations 112–122:

- `LLM::Message`
- `LLM::MessageInferenceResponse`
- `LLM::MessageInferenceMetric`
- `LLM::PolicyEvaluation`
- `LLM::RouteAttempt`
- `LLM::SecurityEvent`
- `LLM::ToolCall`
- `LLM::ToolCallAttempt`
- `LLM::RegistryEvent`

`llm_registry_availability_records` and `llm_tool_records` have no model class in legion-data today — both need new model files created under `lib/legion/data/models/llm/`:

- `lib/legion/data/models/llm/registry_availability_record.rb` — `Sequel::Model(:llm_registry_availability_records)` + identity associations
- `lib/legion/data/models/llm/tool_record.rb` — `Sequel::Model(:llm_tool_records)` + identity associations

Both new models are guarded with `LLM::ModelHelpers.table_available?` consistent with the existing LLM model pattern.

### Memory — new model files (`lib/legion/data/models/memory/*.rb`)

No Sequel model files exist today for `memory_traces` or `memory_associations` in legion-data. Both need to be created:

- `lib/legion/data/models/memory/trace.rb` — `Sequel::Model(:memory_traces)` + identity associations + `one_to_many :associations`
- `lib/legion/data/models/memory/association.rb` — `Sequel::Model(:memory_associations)` + identity associations

A `lib/legion/data/models/memory/model_helpers.rb` following the same `table_available?` pattern as `Apollo::ModelHelpers` and `Identity::ModelHelpers` should be created to guard both models.

---

## Follow-on Work (out of scope for this PR)

These repos need changes after legion-data lands, in dependency order:

### legion-apollo
- Populate `identity_principal_id`, `identity_id`, `identity_canonical_name` from calling identity at ingest time
- Add `access_scope` parameter to `store_knowledge` (default `global`)
- Enforce `access_scope` filter in `handle_query`, `retrieve_relevant`, and `handle_traverse` — pass `requesting_principal_id` through from callers
- Set `access_scope = 'private'` for entries originating from personal channel sources

### lex-apollo
- Pass requesting identity down into `query_knowledge` and `retrieve_relevant` calls
- Ingest path: resolve calling identity and populate identity fields before calling `handle_ingest`

### legion-gaia
- Phase 4 knowledge retrieval: pass the active session's `principal_id` into the Apollo query
- Prevent cross-user knowledge injection by ensuring retrieve_relevant is always identity-scoped

### lex-knowledge
- Document corpus ingestion: set `access_scope = 'global'` explicitly at ingest (already the default, but should be explicit)
- Pass system agent principal for `identity_principal_id` on document chunk entries

### lex-microsoft-teams (and all future lex-* channel extensions)
- At observation ingest time, resolve the Teams user identity to a `principal_id` and populate identity fields
- Set `access_scope` based on channel type: 1:1 chat → `private`, channel message → `team`, public channel → `global`
