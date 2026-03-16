# Legion::Data Changelog

## v1.3.0

### Added
- `Legion::Data::Local` module — parallel local SQLite database for agentic cognitive state persistence
- TimestampMigrator-based migration registration for per-extension local schemas
- `Legion::Data::Local.model(:table)` helper for local-bound Sequel models
- Dev mode fallback: shared DB falls back to SQLite when `dev_mode: true` and network DB unreachable
- New settings: `data.local.enabled`, `data.local.database`, `data.dev_mode`, `data.dev_fallback`
- `Legion::Data.local` accessor for the Local module
- Local connection lifecycle wired into `Legion::Data.setup` / `.shutdown`
- 13 new specs (62 total)

## v1.2.2

### Added
- Migration 014: add missing columns to `relationships` table (`delay`, `chain_id`, `debug`, `allow_new_chains`, `conditions`, `transformation`, `active`) required by lex-tasker query helpers

## v1.2.1

### Added
- Migration 013: `relationships` table with trigger/action foreign keys to functions
- `Legion::Data::Model::Relationship` Sequel model with trigger/action associations
- Relationship model registered in model loader (loaded before Task for association resolution)
- Uncommented `trigger_relationships` and `action_relationships` associations on Function model

## v1.2.0
Moving from BitBucket to GitHub. All git history is reset from this point on
