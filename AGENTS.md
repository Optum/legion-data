Always run a full `bundle exec rspec` and `bundle exec rubocop -A` and fix all errors before committing.

# AGENTS.md - legion-data

## Repo Role

`legion-data` owns persistent storage for LegionIO. Keep this repo focused on database connectivity, Sequel migrations, Sequel models, local SQLite state, extraction persistence, audit/governance storage, identity/RBAC storage, Apollo storage, and the LLM lifecycle ledger.

HTTP APIs, runtime orchestration, extension behavior, and UI concerns belong in their owning repos. This repo should expose clean model contracts that those layers can call.

## Required Commands

Run from the repo root:

```bash
bundle exec rubocop -A
bundle exec rspec --format json --out tmp/rspec_results.json --format progress --out tmp/rspec_progress.txt
```

If RSpec fails, extract failures with:

```bash
jq '[.examples[] | select(.status != "passed") | {file_path, line_number, full_description, status, exception: .exception}]' tmp/rspec_results.json > tmp/rspec_failures.json
```

Do not run partial RSpec or partial RuboCop for release validation.

## Migration Rules

- Never edit published migrations. Add a new migration instead.
- Do not guard migrations with `create_table?`, `drop_table?`, `table_exists?`, `if_exists`, `if_not_exists`, `next if`, or `next unless`.
- Keep migrations split by domain and dependency. Do not hide a whole schema rewrite in one large migration.
- Use portable Sequel DSL by default. Adapter-specific code is acceptable only for adapter-specific features, such as PostgreSQL vector columns.
- Prefer `id` integer primary keys for joins and `uuid` public identifiers for APIs, logs, and external references.
- Avoid JSON columns unless the data is genuinely dynamic provider evidence or cannot be normalized without losing meaning.

## Sequel Association Rules

Use the official Sequel association APIs as the model contract:

- Association API reference: https://sequel.jeremyevans.net/rdoc/classes/Sequel/Model/Associations/ClassMethods.html
- Association basics: https://github.com/jeremyevans/sequel/blob/master/doc/association_basics.rdoc

Required mapping:

| Schema shape | Sequel association |
|--------------|--------------------|
| This table has the foreign key | `many_to_one` |
| Other table has the foreign key | `one_to_many` or `one_to_one` |
| Join table connects both sides | `many_to_many` |
| One associated row through a join table | `one_through_one` |

Rules:

- Define associations for real foreign-key relationships when adding or changing models.
- Prefer association methods and association datasets over ad hoc `where(foreign_key: ...)` lookups in model helpers.
- When names are not inferable, explicitly set `:class`, `:key`, `:primary_key`, `:join_table`, `:left_key`, and `:right_key`.
- Do not create association names that collide with actual column names; Sequel creates methods using the association name.
- Keep namespace models aligned with API/domain shape, for example `Legion::Data::Model::Identity::*`, `LLM::*`, `Apollo::*`, and `RBAC::*`.

## Current Schema Notes

- Migrations currently run through `096`.
- `074`-`076` are mainline Apollo/task/extract migrations.
- `077`-`090` define the LLM lifecycle ledger.
- `091`-`096` define portable identity companion tables.
- Published PostgreSQL identity migrations remain in place; portable identity tables are additive.

## Release Hygiene

For behavior, model, migration, or Ruby code changes:

- Update `lib/legion/data/version.rb`.
- Update `CHANGELOG.md`.
- Update `README.md` when public behavior, schema, configuration, or model surface changes.
- Keep `.gitignore` ignoring `/Gemfile.lock` and `*.gem`.
- Do not include generated DBs, logs, coverage output, built gems, or repo-external `/docs` workspace files in commits.
