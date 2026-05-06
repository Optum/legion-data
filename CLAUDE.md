Always run a full `bundle exec rspec` and `bundle exec rubocop -A` and fix all errors before committing.

# legion-data

`legion-data` is the persistent storage gem for LegionIO. It owns Sequel database connections, numbered migrations, Sequel models, local SQLite state, extract timing persistence, audit/governance storage, identity/RBAC storage, Apollo storage, and the LLM lifecycle ledger.

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

- `lib/legion/data/connection.rb`: shared Sequel connection setup, diagnostics, fallback handling, query logging.
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

## Current Schema Landmarks

- `074`-`076`: Apollo field width, task idempotency, extract step timings.
- `077`-`090`: LLM lifecycle ledger.
- `091`-`096`: portable identity companion tables.
- Namespaced models exist for `Identity::*`, `Apollo::*`, `RBAC::*`, and `LLM::*`.

## Boundaries

- REST APIs belong in LegionIO, not this gem.
- Extension runtime behavior belongs in the owning extension repos.
- Do not commit generated DBs, logs, coverage output, built gems, or workspace `/docs` files from outside this repo.
