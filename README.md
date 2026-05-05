# legion-data

Persistent database storage for the [LegionIO](https://github.com/LegionIO/LegionIO) async job engine and AI coding assistant platform. Provides database connectivity via the [Sequel ORM](https://sequel.jeremyevans.net/), automatic schema migrations (93 numbered migrations), Sequel models for the full LegionIO control plane, and a parallel local SQLite database for on-node agentic cognitive state.

**Version**: 1.7.1 | **Ruby**: >= 3.4 | **License**: Apache-2.0

---

## Supported Databases

| Database | Adapter | Gem | Default |
|----------|---------|-----|---------|
| SQLite | `sqlite` | `sqlite3` (bundled) | Yes |
| MySQL | `mysql2` | `mysql2` (optional) | No |
| PostgreSQL | `postgres` | `pg` (optional) | No |

SQLite is the default and requires no additional gems. For MySQL or PostgreSQL, install the corresponding gem and configure the adapter.

---

## Installation

```bash
gem install legion-data
```

Or add to your `Gemfile`:

```ruby
gem 'legion-data'

# For production databases, add one of these:
# gem 'mysql2', '>= 0.5.5'
# gem 'pg', '>= 1.5'
```

---

## Architecture Overview

```
Legion::Data (singleton module)
├── .setup              # Connect, migrate, load models, set up local DB
├── .connection         # Sequel::Database handle (shared/central)
├── .local              # Legion::Data::Local (local SQLite accessor)
├── .stats              # Combined { shared: ..., local: ... } metrics
├── .reload_static_cache  # Refresh in-memory StaticCache after extension hot-load
├── .shutdown           # Close both shared and local connections
│
├── Connection          # Sequel database connection management
│   ├── .adapter        # Reads adapter from settings (:sqlite, :mysql2, :postgres)
│   ├── .setup          # Establish connection (dev_mode fallback to SQLite if unreachable)
│   ├── .sequel         # Raw Sequel::Database accessor
│   ├── .stats          # Pool metrics, tuning snapshot, adapter-specific DB stats
│   └── .shutdown       # Disconnect and close query file logger
│
├── Migration           # Auto-migration system (93 numbered Sequel DSL migrations)
│
├── Model               # Sequel model autoloader
│   └── Models: Extension, Function, Runner, Node, Task, TaskLog, Setting,
│               DigitalWorker, Relationship, AuditLog, AuditRecord, Chain,
│               RbacRoleAssignment, RbacRunnerGrant, RbacCrossTeamGrant,
│               IdentityProvider, Principal, Identity, IdentityGroup,
│               IdentityGroupMembership,
│               ApolloEntry, ApolloRelation, ApolloExpertise, ApolloAccessLog (PG only),
│               LLM::Conversation, LLM::Message, LLM::MessageInferenceRequest,
│               LLM::MessageInferenceResponse, LLM::RouteAttempt,
│               LLM::MessageInferenceMetric, LLM::ToolCall, LLM::ToolCallAttempt,
│               LLM::ConversationCompaction, LLM::PolicyEvaluation,
│               LLM::SecurityEvent, LLM::RegistryEvent
│
├── Local               # Parallel local SQLite for agentic cognitive state
│   ├── .setup          # Lazy init — creates legionio_local.db on first access
│   ├── .connection     # Sequel::SQLite::Database handle
│   ├── .model(:table)  # Create Sequel::Model bound to local connection
│   ├── .register_migrations(name:, path:)  # Extensions add their own migration dirs
│   ├── .stats          # Local SQLite metrics (PRAGMAs, file size, registered migrations)
│   └── .shutdown       # Close local connection
│
├── Extract             # 10-handler text extraction registry (txt/md/csv/json/jsonl/html/xlsx/docx/pdf/pptx/vtt)
├── Spool               # Filesystem write buffer for DB-unavailable scenarios
├── Rls                 # PostgreSQL row-level security helpers (tenant isolation)
├── StorageTiers        # Hot/warm/cold archival lifecycle
├── EventStore          # Append-only governance event store with hash chain integrity
├── Vector              # Reusable pgvector helpers (cosine_search, l2_search, ensure_extension!)
└── Settings            # Default configuration with per-adapter credential presets
```

### Two-Database Architecture

`legion-data` maintains two independent databases:

1. **Shared DB** (SQLite / MySQL / PostgreSQL) — control plane data: extensions, tasks, runners, nodes, settings, audit logs, relationships. Shared across the cluster.
2. **Local DB** (always SQLite) — agentic cognitive state: memory traces, trust scores, dream journals. On-node only; no cross-database joins.

Deleting `legionio_local.db` provides cryptographic erasure — no residual data.

---

## Usage

```ruby
require 'legion/data'

# Set up shared DB + local SQLite, run migrations, load models
Legion::Data.setup

# Access the Sequel database handle
Legion::Data.connection              # => Sequel::Database

# Access models
Legion::Data::Model::Extension.all  # => Sequel::Dataset
Legion::Data::Model::Task.first(id: 42)
Legion::Data::Model::Setting.where(key: 'my_setting').first

# Access local cognitive state DB
Legion::Data.local.connection        # => Sequel::SQLite::Database
Legion::Data.local.connected?        # => true
Legion::Data.local.db_path           # => "legionio_local.db"

# Check connection health
Legion::Data.connected?              # => true
Legion::Data.stats                   # => { shared: {...}, local: {...} }

# Shut down both connections
Legion::Data.shutdown
```

### Local Database (Agentic Cognitive State)

Extensions register their own migration directories and create models bound to the local connection:

```ruby
# Register extension migrations (called during extension setup)
Legion::Data::Local.register_migrations(name: :memory, path: '/path/to/migrations')

# Create a model class bound to the local DB
MyMemoryTrace = Legion::Data::Local.model(:memory_traces)
MyMemoryTrace.all  # queries legionio_local.db, never the shared DB
```

### Text Extraction

`Legion::Data::Extract` provides a handler registry for extracting text from documents, used by `lex-knowledge` for corpus ingestion:

```ruby
text = Legion::Data::Extract.extract('/path/to/document.pdf')
text = Legion::Data::Extract.extract('/path/to/data.csv')
```

Supported formats: `.txt`, `.md`, `.csv`, `.json`, `.jsonl`, `.html`, `.xlsx`, `.docx`, `.pdf`, `.pptx`, `.vtt`

### Filesystem Spool (Write Buffer)

When the database is unavailable, `Legion::Data::Spool` buffers writes to `~/.legionio/data/spool/` and replays once the connection is restored:

```ruby
spool = Legion::Data::Spool.for(Legion::Extensions::MyLex)
spool.write({ task_id: SecureRandom.uuid, data: payload })
spool.drain { |entry| process(entry) }
```

### Row-Level Security (PostgreSQL)

`Legion::Data::Rls` provides tenant isolation via PostgreSQL session variables (migration 043):

```ruby
Legion::Data::Rls.with_tenant(tenant_id) do
  Legion::Data::Model::Task.all  # scoped to tenant_id via RLS policy
end
```

### Permission Checks

```ruby
Legion::Data.can_write?(:tasks)  # => true (SQLite always true)
Legion::Data.can_read?(:tasks)   # => true
Legion::Data.reset_privileges!   # clear cached privilege checks
```

---

## Configuration

All settings live under the `data` key. The adapter controls which options apply.

### SQLite (default)

```json
{
  "data": {
    "adapter": "sqlite",
    "creds": {
      "database": "legionio.db"
    }
  }
}
```

### MySQL

```json
{
  "data": {
    "adapter": "mysql2",
    "creds": {
      "username": "legion",
      "password": "legion",
      "database": "legionio",
      "host": "127.0.0.1",
      "port": 3306
    }
  }
}
```

### PostgreSQL

```json
{
  "data": {
    "adapter": "postgres",
    "creds": {
      "user": "legion",
      "password": "legion",
      "database": "legionio",
      "host": "127.0.0.1",
      "port": 5432
    }
  }
}
```

PostgreSQL with `pgvector` is required for Apollo models:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Full Configuration Reference

```json
{
  "data": {
    "adapter": "sqlite",
    "connected": false,
    "dev_mode": false,
    "dev_fallback": true,
    "connect_on_start": true,

    "max_connections": 25,
    "pool_timeout": 5,
    "preconnect": "concurrently",
    "single_threaded": false,
    "test": true,

    "log": false,
    "query_log": false,
    "log_warn_duration": 1,
    "sql_log_level": "debug",

    "connection_validation": true,
    "connection_validation_timeout": 600,
    "connection_expiration": true,
    "connection_expiration_timeout": 14400,

    "read_replica_url": null,
    "replicas": [],

    "creds": { "database": "legionio.db" },

    "migrations": {
      "continue_on_fail": false,
      "auto_migrate": true
    },
    "models": {
      "continue_on_load_fail": false,
      "autoload": true
    },
    "local": {
      "enabled": true,
      "database": "legionio_local.db",
      "migrations": { "auto_migrate": true }
    },
    "cache": {
      "connected": false,
      "auto_enable": false,
      "static_cache": false,
      "ttl": 60
    }
  }
}
```

### Dev Mode Fallback

When `dev_mode: true` and a network database is unreachable, the shared connection automatically falls back to SQLite:

```json
{ "data": { "dev_mode": true, "dev_fallback": true } }
```

### HashiCorp Vault Integration

When Vault is connected, credentials are fetched dynamically from `database/creds/legion`, overriding any static `creds` block.

### Caching

Two independent caching tiers, both disabled by default:

| Tier | Setting | Models | Backend |
|------|---------|--------|---------|
| **StaticCache** | `data.cache.static_cache: true` | Extension, Runner, Function | In-process frozen Ruby hash |
| **External Cache** | `data.cache.auto_enable: true` + `Legion::Cache` | Relationship, Node, Setting | Redis/Memcached/Memory |

```ruby
# After hot-loading extensions, refresh the static cache:
Legion::Data.reload_static_cache
```

### Read Replicas (PostgreSQL)

```json
{
  "data": {
    "read_replica_url": "postgres://user:pass@replica1/db",
    "replicas": ["postgres://user:pass@replica2/db"]
  }
}
```

---

## Data Models

| Model | Table | Description |
|-------|-------|-------------|
| `Extension` | `extensions` | Installed LEX extensions |
| `Function` | `functions` | Available functions per extension (with embeddings) |
| `Runner` | `runners` | Runner definitions (AMQP routing keys) |
| `Node` | `nodes` | Cluster node registry |
| `Task` | `tasks` | Task instances |
| `TaskLog` | `task_logs` | Task execution logs |
| `Setting` | `settings` | Persistent settings store |
| `DigitalWorker` | `digital_workers` | Digital worker registry |
| `Relationship` | `relationships` | Task trigger/action chains between functions |
| `Chain` | `chains` | Task execution chains |
| `AuditLog` | `audit_log` | Tamper-evident audit trail with hash chain |
| `AuditRecord` | `audit_records` | Structured audit records |
| `RbacRoleAssignment` | `rbac_role_assignments` | RBAC principal -> role mappings |
| `RbacRunnerGrant` | `rbac_runner_grants` | Per-runner permission grants |
| `RbacCrossTeamGrant` | `rbac_cross_team_grants` | Cross-team access grants |
| `IdentityProvider` | `identity_providers` | Identity provider registrations |
| `Principal` | `principals` | Authentication principals |
| `Identity` | `identities` | Identity records tied to principals |
| `IdentityGroup` | `identity_groups` | Identity groups |
| `IdentityGroupMembership` | `identity_group_memberships` | Group membership records |
| `ApolloEntry` | `apollo_entries` | Knowledge entries — PostgreSQL only (pgvector) |
| `ApolloRelation` | `apollo_relations` | Relations between Apollo entries — PostgreSQL only |
| `ApolloExpertise` | `apollo_expertise` | Per-agent domain expertise — PostgreSQL only |
| `ApolloAccessLog` | `apollo_access_log` | Apollo access audit log — PostgreSQL only |

Apollo models require PostgreSQL with the `pgvector` extension. They are skipped silently on SQLite and MySQL.

The `Legion::Data::Model::Identity::*`, `Apollo::*`, `RBAC::*`, and `LLM::*` namespaces provide cleaner Sequel model names for API-facing code while preserving the legacy flat model classes.

### LLM Lifecycle Models

| Model | Table | Description |
|-------|-------|-------------|
| `LLM::Conversation` | `llm_conversations` | Conversation container tied to the base user identity |
| `LLM::Message` | `llm_messages` | Model-visible conversation transcript messages |
| `LLM::MessageInferenceRequest` | `llm_message_inference_requests` | Provider request assembled from message, context, tools, policy, and routing inputs |
| `LLM::MessageInferenceResponse` | `llm_message_inference_responses` | Provider/runtime response for one inference request |
| `LLM::RouteAttempt` | `llm_route_attempts` | Provider/model/runner routing attempts, including failures and escalations |
| `LLM::MessageInferenceMetric` | `llm_message_inference_metrics` | Token, latency, cost, and finance usage metrics for an inference pair |
| `LLM::ToolCall` | `llm_tool_calls` | Tool calls requested by an LLM provider response |
| `LLM::ToolCallAttempt` | `llm_tool_call_attempts` | Execution attempts, retries, failures, and results for provider-requested tool calls |
| `LLM::ConversationCompaction` | `llm_conversation_compactions` | Conversation-scoped compaction events |
| `LLM::PolicyEvaluation` | `llm_policy_evaluations` | Policy, classification, RBAC, and enforcement decisions for inference requests |
| `LLM::SecurityEvent` | `llm_security_events` | Security-relevant events tied to conversation, inference, response, or tool attempts |
| `LLM::RegistryEvent` | `llm_registry_events` | Provider/model registry availability and health events |

---

## Dependencies

| Gem | Purpose |
|-----|---------|
| `sequel` (>= 5.70) | ORM and migration framework |
| `sqlite3` (>= 2.0) | SQLite adapter (default, bundled) |
| `csv` (>= 3.2) | CSV extraction handler |
| `legion-json` | JSON serialization via Legion::JSON |
| `legion-logging` (>= 1.5.0) | Structured logging |
| `legion-settings` (>= 1.3.26) | Configuration management |
| `mysql2` (>= 0.5.5) | MySQL adapter (optional) |
| `pg` (>= 1.5) | PostgreSQL adapter (optional) |

---

## Migrations

93 numbered Sequel DSL migrations run automatically on startup (`auto_migrate: true`). Key milestones:

| Range | What was added |
|-------|---------------|
| 001–011 | Core schema: nodes, settings, extensions, runners, functions, tasks, digital workers, value metrics |
| 012 | Apollo tables (PG only: pgvector, uuid-ossp, 4 tables) |
| 013–014 | Relationships table with trigger/action FK chains |
| 015 | RBAC tables |
| 017–019 | Audit log with tamper-evident hash chain |
| 020–025 | Webhooks, archive tables, memory traces, tenant partitions |
| 026 | Function embeddings (description + vector on functions) |
| 028–030 | Agent clusters and approval queue |
| 047–048 | Apollo knowledge capture + financial logging (UAIS cost recovery, 7 tables) |
| 050 | Critical indexes across 13 tables |
| 058–067 | Audit records, chains, knowledge tiers, tool embedding cache, identity system (providers, principals, identities, groups) |
| 068–071 | Entity type on audit records, principal on nodes, approval queue resume, engine on relationships |
| 074–087 | Portable LLM lifecycle schema: conversations, messages, inference requests/responses, route attempts, inference metrics, provider-requested tool calls, compactions, policy/security, and registry events |
| 088–093 | Portable identity companion schema with integer primary keys, public UUIDs, provider capabilities, principals, identities, groups, memberships, and audit log |

Run migrations standalone:

```bash
bundle exec legionio_migrate
```

---

## CLI Executable

`exe/legionio_migrate` runs database migrations standalone, outside the full LegionIO service:

```bash
bundle exec legionio_migrate
```

---

## Role in LegionIO

`legion-data` is optional but provides core platform persistence. It initializes during `Legion::Service` startup (after transport). Key responsibilities:

1. Extension and function registry
2. Task scheduling, logging, and relationship chains
3. Node cluster membership tracking
4. Persistent settings storage
5. Digital worker registry (AI-as-labor platform)
6. RBAC assignment tables
7. Audit log with tamper-evident hash chain
8. Governance event store with append-only integrity
9. Apollo shared knowledge store (PostgreSQL + pgvector, used by `lex-apollo`)
10. Local SQLite for agentic cognitive state — always on-node, independent of shared DB
11. Financial logging for UAIS cost recovery
12. Global tool embedding cache (L4 tier for `Legion::Tools::EmbeddingCache`)
13. Unified identity system (providers, principals, identities, groups)
14. LLM lifecycle ledger for audit, finance metrics, routing reconstruction, tool calls, and security incident lineage

---

## Contributing

```bash
git clone https://github.com/LegionIO/legion-data
cd legion-data
bundle install
bundle exec rspec        # all tests must pass
bundle exec rubocop -A   # zero offenses expected
```

Follow the [LegionIO contribution guide](https://github.com/LegionIO/.github/blob/main/CONTRIBUTING.md). Open a PR against `main`.

---

**Maintained by**: Matthew Iverson ([@Esity](https://github.com/Esity))
