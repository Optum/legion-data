# legion-data

Persistent database storage for the [LegionIO](https://github.com/LegionIO/LegionIO) framework. Provides database connectivity via Sequel ORM, automatic schema migrations, and data models for extensions, functions, runners, nodes, tasks, settings, digital workers, task relationships, and Apollo shared knowledge tables.

**Version**: 1.4.4

## Supported Databases

| Database | Adapter | Gem | Default |
|----------|---------|-----|---------|
| SQLite | `sqlite` | `sqlite3` (included) | Yes |
| MySQL | `mysql2` | `mysql2` | No |
| PostgreSQL | `postgres` | `pg` | No |

SQLite is the default adapter and requires no external database server. For MySQL or PostgreSQL, install the corresponding gem and set the adapter in your configuration.

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
| `Runner` | `runners` | Runner definitions (extension + function bindings) |
| `Node` | `nodes` | Cluster node registry |
| `Task` | `tasks` | Task instances |
| `TaskLog` | `task_logs` | Task execution logs |
| `Setting` | `settings` | Persistent settings store |
| `DigitalWorker` | `digital_workers` | Digital worker registry (AI-as-labor platform) |
| `Relationship` | `relationships` | Task trigger/action relationships between functions |
| `ApolloEntry` | `apollo_entries` | Apollo shared knowledge entries (PostgreSQL only) |
| `ApolloRelation` | `apollo_relations` | Relations between Apollo knowledge entries (PostgreSQL only) |
| `ApolloExpertise` | `apollo_expertise` | Per-agent domain expertise tracking (PostgreSQL only) |
| `ApolloAccessLog` | `apollo_access_log` | Apollo entry access audit log (PostgreSQL only) |

Apollo models require PostgreSQL with the `pgvector` extension. They are skipped silently on SQLite and MySQL.

Migration 026 adds `description` (TEXT) and `embedding` (TEXT, JSON-serialized vector) columns to the `functions` table, plus a `embedding_vector vector(1536)` column with HNSW cosine index on PostgreSQL for semantic similarity search of runner functions.

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

v1.3.0 introduces `Legion::Data::Local`, a parallel SQLite database always stored locally on the node. It is used for agentic cognitive state persistence (memory traces, trust scores, dream journals, etc.) and is independent of the shared database.

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

The local database file (`legionio_local.db` by default) can be deleted for cryptographic erasure — no residual data. This is used by `lex-privatecore`.

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

PostgreSQL with `pgvector` is required for Apollo models. Install the extension in your database before running migrations:

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

Set `enabled: false` to disable local SQLite entirely.

### Spool (Filesystem Buffer)

`Legion::Data::Spool` provides a filesystem-backed write buffer for extensions. When the database is unavailable, task data can be written to `~/.legionio/data/spool/` and replayed once the connection is restored.

```ruby
spool = Legion::Data::Spool.for(Legion::Extensions::MyLex)
spool.write({ task_id: SecureRandom.uuid, data: payload })
spool.drain { |entry| process(entry) }
```

### Dev Mode Fallback

When `dev_mode: true` and a network database (MySQL/PostgreSQL) is unreachable, the shared connection falls back to SQLite automatically instead of raising.

```json
{
  "data": {
    "dev_mode": true,
    "dev_fallback": true
  }
}
```

### HashiCorp Vault Integration

When Vault is connected and a `database/creds/legion` secret path exists, credentials are fetched dynamically from Vault at connection time, overriding any static `creds` configuration.

## Requirements

- Ruby >= 3.4

## License

Apache-2.0
