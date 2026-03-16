# legion-data: Persistent Storage for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Manages persistent database storage for the LegionIO framework. Supports SQLite (default), MySQL, and PostgreSQL via Sequel ORM. Provides automatic schema migrations and data models for extensions, functions, runners, nodes, tasks, and settings.

**GitHub**: https://github.com/LegionIO/legion-data
**License**: Apache-2.0

## Supported Databases

| Database | Adapter | Gem | Use Case |
|----------|---------|-----|----------|
| SQLite | `sqlite` | `sqlite3` (bundled) | Default, dev/test, single-node |
| MySQL | `mysql2` | `mysql2` (optional) | Production |
| PostgreSQL | `postgres` | `pg` (optional) | Production |

Adapter is set via `Legion::Settings[:data][:adapter]`. All migrations use Sequel DSL for cross-database compatibility.

## Architecture

```
Legion::Data (singleton module)
├── .setup             # Connect, migrate, load models, setup cache, setup local
├── .connection        # Sequel database handle (shared/central)
├── .local             # Legion::Data::Local accessor
├── .shutdown          # Close both connections
│
├── Connection         # Sequel database connection management (shared)
│   ├── .adapter       # Reads from settings (sqlite, mysql2, postgres)
│   ├── .setup         # Establish connection (dev_mode fallback to SQLite if network DB unreachable)
│   ├── .sequel        # Raw Sequel::Database accessor
│   └── .shutdown      # Close connection
│
├── Local              # Local SQLite database for agentic cognitive state
│   ├── .setup         # Lazy init — creates legionio_local.db on first access
│   ├── .connection    # Sequel::SQLite::Database handle
│   ├── .connected?    # Whether local DB is active
│   ├── .db_path       # Path to the local SQLite file
│   ├── .model(:table) # Create Sequel::Model bound to local connection
│   ├── .register_migrations(name:, path:) # Extensions register their migration dirs
│   ├── .shutdown      # Close local connection
│   └── .reset!        # Clear all state (testing)
│
├── Migration          # Auto-migration system (14 migrations, Sequel DSL)
│   └── migrations/
│       ├── 001_add_schema_columns
│       ├── 002_add_nodes
│       ├── 003_add_settings
│       ├── 004_add_extensions
│       ├── 005_add_runners
│       ├── 006_add_functions
│       ├── 007_add_default_extensions
│       ├── 008_add_tasks
│       ├── 009_add_digital_workers
│       ├── 010_add_value_metrics
│       ├── 011_add_extensions_registry
│       ├── 012_add_apollo_tables
│       ├── 013_add_relationships
│       └── 014_add_relationship_columns
│
├── Model              # Sequel model loader
│   └── Models/
│       ├── Extension  # Installed LEX extensions
│       ├── Function   # Available functions per extension
│       ├── Runner     # Runner definitions (extension + function bindings)
│       ├── Node       # Cluster node registry
│       ├── Task       # Task instances
│       ├── TaskLog    # Task execution logs
│       ├── Setting    # Persistent settings store
│       └── DigitalWorker  # Digital worker registry (AI-as-labor platform)
│   Note: value_metrics table (migration 010) is accessed via raw Sequel dataset,
│         not via a named Sequel::Model subclass.
│
├── Settings           # Default DB config with per-adapter credential presets
└── Version
```

### Key Design Patterns

- **Two-Database Architecture**: Shared (MySQL/PG/SQLite) for control plane data + Local (always SQLite) for agentic cognitive state. Two files, always separate, no cross-database joins.
- **Adapter-Driven**: `Connection.adapter` reads from settings; SQLite uses `Sequel.sqlite(path)`, others use `Sequel.connect`
- **Dev Mode Fallback**: When `dev_mode: true` and network DB unreachable, shared connection falls back to SQLite (`legionio.db`) with warning log
- **Cross-DB Migrations**: Shared migrations use IntegerMigrator (Sequel DSL), local migrations use TimestampMigrator (per-extension registration)
- **Auto-Migration**: Runs Sequel migrations on startup (`auto_migrate: true` by default)
- **Sequel ORM**: Shared models are `Sequel::Model` subclasses (inherit global connection). Local models use `Legion::Data::Local.model(:table)` (explicit connection binding).
- **Optional Caching**: `setup_cache` checks for `Legion::Cache` presence but Sequel model caching is currently disabled (code is commented out, pending implementation)
- **Cryptographic Erasure**: Deleting `legionio_local.db` is a hard guarantee — no residual data. Used by `lex-privatecore`.
- **CLI Executable**: Ships with `legionio_migrate` executable in `exe/` for running database migrations standalone

## Default Settings

```json
{
  "adapter": "sqlite",
  "connected": false,
  "connection": {
    "max_connections": 10,
    "preconnect": false
  },
  "creds": {
    "database": "legionio.db"
  },
  "migrations": {
    "auto_migrate": true
  },
  "models": {
    "autoload": true
  }
}
```

Per-adapter credential defaults are defined in `Settings::CREDS`:
- **sqlite**: `{ database: "legionio.db" }`
- **mysql2**: `{ username: "legion", password: "legion", database: "legionio", host: "127.0.0.1", port: 3306 }`
- **postgres**: `{ user: "legion", password: "legion", database: "legionio", host: "127.0.0.1", port: 5432 }`

## Dependencies

| Gem | Purpose |
|-----|---------|
| `sequel` (>= 5.70) | ORM and migration framework |
| `sqlite3` (>= 2.0) | SQLite adapter (default, bundled) |
| `mysql2` (>= 0.5.5) | MySQL adapter (optional) |
| `pg` (>= 1.5) | PostgreSQL adapter (optional) |
| `legion-logging` | Logging |
| `legion-settings` | Configuration |

## File Map

| Path | Purpose |
|------|---------|
| `lib/legion/data.rb` | Module entry, setup/shutdown lifecycle |
| `lib/legion/data/connection.rb` | Sequel database connection (adapter selection) |
| `lib/legion/data/migration.rb` | Migration runner |
| `lib/legion/data/migrations/` | 10 numbered migration files (Sequel DSL) |
| `lib/legion/data/model.rb` | Model autoloader |
| `lib/legion/data/models/` | Sequel models (Extension, Function, Runner, Node, Task, TaskLog, Setting, DigitalWorker) |
| `lib/legion/data/settings.rb` | Default configuration with per-adapter credential presets |
| `lib/legion/data/version.rb` | VERSION constant |
| `exe/legionio_migrate` | CLI executable for running database migrations standalone |

## Role in LegionIO

Optional persistent storage initialized during `Legion::Service` startup (after transport). Provides:
1. Extension and function registry (which LEXs are installed, what functions they expose)
2. Task scheduling and logging
3. Node cluster membership tracking
4. Persistent settings storage

---

**Maintained By**: Matthew Iverson (@Esity)
