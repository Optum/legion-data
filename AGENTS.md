Always run a full `bundle exec rspec` and `bundle exec rubocop -A` and fix all errors before committing.

# legion-data

`legion-data` is the persistent database storage gem for the LegionIO async job engine framework. It provides database connectivity via the Sequel ORM, automatic schema migrations (70+ numbered migrations), and Sequel models for the full LegionIO control plane: extensions, functions, runners, nodes, tasks, settings, digital workers, task relationships, Apollo shared knowledge tables (PostgreSQL only), RBAC, tenants, audit log, governance events, and archive tables.

It also ships a parallel local SQLite database (`Legion::Data::Local`) for on-node agentic cognitive state persistence (memory traces, trust scores, etc.), independent of the shared database.

## Key entry points

- `Legion::Data.setup` — connect, migrate, load models, set up local DB
- `Legion::Data::Model::*` — Sequel model classes
- `Legion::Data::Local` — local SQLite for agentic state
- `Legion::Data::Extract` — text extraction from documents (pdf, docx, csv, etc.)
- `Legion::Data::Spool` — filesystem write buffer for DB-unavailable scenarios

## Testing

```bash
cd /path/to/legion-data
bundle install
bundle exec rspec
bundle exec rubocop -A
```
