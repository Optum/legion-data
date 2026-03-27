# legion-data

Persistent database storage for the [LegionIO](https://github.com/LegionIO/LegionIO) framework. Provides database connectivity via Sequel ORM, automatic schema migrations (47 numbered migrations), and data models for extensions, functions, runners, nodes, tasks, settings, digital workers, task relationships, Apollo shared knowledge tables (PostgreSQL only), tenants, audit log, and archive tables.

**Version**: 1.6.6

## Supported Databases

| Database | Adapter | Gem | Default |
|----------|---------|-----|---------|
| SQLite | `sqlite` | `sqlite3` (included) | Yes |
| MySQL | `mysql2` | `mysql2` | No |
| PostgreSQL | `postgres` | `pg` | No |

SQLite is the default adapter. For MySQL or PostgreSQL, install the corresponding gem and set the adapter in your configuration.

## Installation

```bash
gem install legion-data
```

Or add to your Gemfile:

```ruby
gem 'legion-data'

# Add one of these for production databases:
# gem 'mysql2', '>= 0.5.5'
# gem 'pg', '>= 1.5'
```

## Data Models

| Model | Table | Description |
|-------|-------|-------------|
| `Extension` | `extensions` | Installed LEX extensions |
| `Function` | `functions` | Available functions per extension |
| `Runner` | `runners` | Runner definitions |
| `Node` | `nodes` | Cluster node registry |
| `Task` | `tasks` | Task instances |
| `TaskLog` | `task_logs` | Task execution logs |
| `Setting` | `settings` | Persistent settings store |
| `DigitalWorker` | `digital_workers` | Digital worker registry |
| `Relationship` | `relationships` | Task trigger/action relationships between functions |
| `AuditLog` | `audit_log` | Tamper-evident audit trail with hash chain |
| `RbacRoleAssignment` | `rbac_role_assignments` | RBAC principal -> role mappings |
| `RbacRunnerGrant` | `rbac_runner_grants` | Per-runner permission grants |
| `RbacCrossTeamGrant` | `rbac_cross_team_grants` | Cross-team access grants |
| `ApolloEntry` | `apollo_entries` | Apollo knowledge entries — PostgreSQL only (pgvector) |
| `ApolloRelation` | `apollo_relations` | Relations between Apollo entries — PostgreSQL only |
| `ApolloExpertise` | `apollo_expertise` | Per-agent domain expertise — PostgreSQL only |
| `ApolloAccessLog` | `apollo_access_log` | Apollo access audit log — PostgreSQL only |

Apollo models require PostgreSQL with the `pgvector` extension. They are skipped silently on SQLite and MySQL.

## Usage

```ruby
require 'legion/data'

# Standard setup (shared DB + local SQLite)
Legion::Data.setup
Legion::Data.connection              # => Sequel::Database (shared)
Legion::Data.local.connection        # => Sequel::SQLite::Database (local cognitive state)
Legion::Data::Model::Extension.all  # => Sequel::Dataset
```

### Local Database

`Legion::Data::Local` is a parallel SQLite database always stored locally on the node. Used for agentic cognitive state persistence (memory traces, trust scores, dream journals) and is independent of the shared database.

```ruby
# Local DB is set up automatically during Legion::Data.setup
# Extensions register their own migration directories
Legion::Data::Local.register_migrations(name: :memory, path: '/path/to/migrations')

# Create a model bound to the local connection
MyModel = Legion::Data::Local.model(:my_table)

# Check status
Legion::Data::Local.connected?   # => true
Legion::Data::Local.db_path      # => "legionio_local.db"
```

Deleting `legionio_local.db` provides cryptographic erasure — no residual data.

### Text Extraction

`Legion::Data::Extract` provides a 10-handler registry for extracting text from documents. Supports: `.txt`, `.md`, `.csv`, `.json`, `.jsonl`, `.html`, `.xlsx`, `.docx`, `.pdf`, `.pptx`. Used by `lex-knowledge` for corpus ingestion.

```ruby
text = Legion::Data::Extract.extract('/path/to/document.pdf')
```

### Row-Level Security

`Legion::Data::Rls` provides tenant isolation helpers for PostgreSQL (migration 043). Sets `app.current_tenant_id` session variable before queries and resets it after.

### Spool (Filesystem Buffer)

`Legion::Data::Spool` provides a filesystem-backed write buffer. When the database is unavailable, data is written to `~/.legionio/data/spool/` and replayed once the connection is restored.

```ruby
spool = Legion::Data::Spool.for(Legion::Extensions::MyLex)
spool.write({ task_id: SecureRandom.uuid, data: payload })
spool.drain { |entry| process(entry) }
```

## Configuration

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

### Local Database

```json
{
  "data": {
    "local": {
      "enabled": true,
      "database": "legionio_local.db",
      "migrations": {
        "auto_migrate": true
      }
    }
  }
}
```

### Dev Mode Fallback

When `dev_mode: true` and a network database is unreachable, the shared connection falls back to SQLite automatically:

```json
{
  "data": {
    "dev_mode": true,
    "dev_fallback": true
  }
}
```

### HashiCorp Vault Integration

When Vault is connected, credentials are fetched dynamically from `database/creds/legion`, overriding any static `creds` configuration.

## Requirements

- Ruby >= 3.4

## License

Apache-2.0
