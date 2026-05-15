Always run a full `bundle exec rspec` and `bundle exec rubocop -A` and fix all errors before committing.

# legion-data

Persistent storage gem for LegionIO. Owns Sequel database connections, numbered migrations, models, local SQLite state, extract timing persistence, audit/governance storage, identity/RBAC storage, Apollo storage, and the LLM lifecycle ledger.

## Commands

```bash
bundle install
bundle exec rubocop -A
bundle exec rspec --format json --out tmp/rspec_results.json --format progress --out tmp/rspec_progress.txt
```

RSpec output belongs in `tmp/`. On failure, extract only failures:

```bash
jq '[.examples[] | select(.status != "passed") | {file_path, line_number, full_description, status, exception: .exception}]' tmp/rspec_results.json > tmp/rspec_failures.json
```

## Architecture

- `lib/legion/data/connection.rb`: Sequel connection setup, diagnostics, fallback, query logging.
- `lib/legion/data/migration.rb`: numbered Sequel migrations.
- `lib/legion/data/model.rb`: shared model loader.
- `lib/legion/data/models/`: flat and namespaced Sequel model classes.
- `lib/legion/data/local.rb`: local SQLite database for on-node state.
- `lib/legion/data/extract.rb`: text extraction and persisted extract step timings.
- `lib/legion/data/spool.rb`: filesystem write buffer when DB writes are unavailable.

## Migration Rules

- Never edit published migrations. Add a new migration.
- Do not guard migrations with `create_table?`, `drop_table?`, `table_exists?`, `if_exists`, `if_not_exists`, `next if`, or `next unless`.
- Keep migrations small enough to diagnose and roll back. Split by domain and dependency.
- Use portable Sequel DSL unless the feature truly requires adapter-specific behavior.
- Use integer `id` primary keys for joins and public `uuid` columns for APIs/logs/external references.
- Normalize stable fields. Use JSON only for genuinely dynamic provider payloads or evidence.

## Sequel ORM Rules

Use Sequel associations as the object graph. References:
- https://sequel.jeremyevans.net/rdoc/classes/Sequel/Model/Associations/ClassMethods.html
- https://github.com/jeremyevans/sequel/blob/master/doc/association_basics.rdoc

Association mapping:
- Foreign key on this model: `many_to_one`.
- Foreign key on the associated model: `one_to_many` or `one_to_one`.
- Join table between models: `many_to_many`.
- Single associated record through a join table: `one_through_one`.

When Sequel cannot infer names, set `:class`, `:key`, `:primary_key`, `:join_table`, `:left_key`, and `:right_key` explicitly. Do not create association names that collide with real columns.

## Common Fields Standard

All new tables in legion-data should follow this column convention. Required fields must be present on every table. Optional fields are added when the domain warrants them.

### Required

| Column | Type | Purpose |
|--------|------|---------|
| `id` | `INTEGER PRIMARY KEY` (auto-increment) | Internal join key — never exposed externally |
| `identity_principal_id` | `INTEGER` FK → `identity_principals.id` | The principal who caused this row to exist |
| `identity_id` | `INTEGER` FK → `identities.id` | The specific provider-bound identity credential |
| `identity_canonical_name` | `VARCHAR(255)` | Denormalized snapshot of the identity's canonical name for fast filtering without joins. This value is a point-in-time copy — it may become stale if the principal is renamed. Use the FK join for authoritative lookups. |
| `created_at` | `TIMESTAMPTZ` | Row creation time |
| `updated_at` | `TIMESTAMPTZ` | Last modification time |

### Optional (add when applicable)

| Column | Type | Purpose |
|--------|------|---------|
| `expires_at` | `TIMESTAMPTZ` | TTL / archival eligibility |
| `content_type` | `VARCHAR(...)` | Classifier for the row's payload kind |
| `conversation_id` | `INTEGER` FK → `llm_conversations.id` | Links to the LLM conversation that produced this row |
| `contains_phi` | `BOOLEAN` | Row contains Protected Health Information |
| `contains_pii` | `BOOLEAN` | Row contains Personally Identifiable Information |

### Naming rules

- Identity FKs always use `identity_principal_id` and `identity_id` — never `agent_id`, `principal_id`, `user_id`, or other loose variants for new tables.
- The denormalized string field is always `identity_canonical_name` — not `canonical_name`, `actor`, `agent_id`, or `identity_name`.
- Existing columns (`agent_id`, `source_agent`, `submitted_by`, `actor`, etc.) on pre-existing tables are **not renamed or removed** — they are historical record and intentionally left as-is. New identity columns are purely additive.

## Current Schema Landmarks

- `074`-`076`: Apollo field width, task idempotency, extract step timings.
- `077`-`090`: LLM lifecycle ledger.
- `091`-`096`: portable identity companion tables.
- Namespaced models: `Identity::*`, `Apollo::*`, `RBAC::*`, `LLM::*`.

## Boundaries

- REST APIs belong in LegionIO, not this gem.
- Extension runtime behavior belongs in the owning extension repos.
- Do not commit generated DBs, logs, coverage output, built gems, or workspace `/docs` files from outside this repo.
