# Legion::Data Changelog

## v1.3.7

### Added
- Migration 020: `webhooks`, `webhook_deliveries`, `webhook_dead_letters` tables

### Fixed
- Migration 019: guard against duplicate column adds when `record_hash` already exists from migration 017

## v1.3.6

### Added
- Migration 019: adds `record_hash`, `previous_hash`, `retention_tier` columns to `audit_log`

## v1.3.5

### Added
- `Legion::Data::EventStore`: append-only governance event store with stream semantics
- Hash chain integrity verification for tamper detection
- `EventStore::Projection` base class with `build_from` stream replay
- `ConsentState` projection: rebuild consent state from event history
- `GovernanceTimeline` projection: chronological governance event timeline
- Migration 018: governance_events table with stream/sequence indexing

## v1.3.4

### Added
- `Legion::Data::Encryption::Cipher`: AES-256-GCM with versioned binary format, random IV, and AAD
- `Legion::Data::Encryption::KeyProvider`: Vault-backed key derivation with local fallback for dev mode
- `Legion::Data::Encryption::SequelPlugin`: transparent `encrypted_column` DSL for Sequel models
- Per-tenant key scope support for cryptographic erasure compliance

## v1.3.3

### Added
- Migration 017: `audit_log` table with SHA-256 hash chain columns (`record_hash`, `prev_hash`)
- `Legion::Data::Model::AuditLog` immutable Sequel model with event type/status validation
- Indexes on `event_type`, `principal_id`, and `created_at` for audit query performance

## v1.3.2

### Added
- Migration 016: worker health columns (`health_status`, `last_heartbeat_at`, `health_node` on digital_workers; `metrics`, `hosted_worker_ids`, `version` on nodes)
- `DigitalWorker#health_status` validation against `HEALTH_STATUSES` (`online`, `offline`, `unknown`)
- `DigitalWorker#online?` and `DigitalWorker#offline?` convenience methods
- `Node#parsed_metrics` and `Node#parsed_hosted_worker_ids` JSON deserialization helpers

## v1.3.1

### Added
- Migration 015: RBAC tables (rbac_role_assignments, rbac_runner_grants, rbac_cross_team_grants)
- `Legion::Data::Model::RbacRoleAssignment` Sequel model with expiry and validation
- `Legion::Data::Model::RbacRunnerGrant` Sequel model with actions_list helper
- `Legion::Data::Model::RbacCrossTeamGrant` Sequel model with cross-team validation

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
