# Legion::Data Changelog

## v1.2.1

### Added
- Migration 013: `relationships` table with trigger/action foreign keys to functions
- `Legion::Data::Model::Relationship` Sequel model with trigger/action associations
- Relationship model registered in model loader (loaded before Task for association resolution)
- Uncommented `trigger_relationships` and `action_relationships` associations on Function model

## v1.2.0
Moving from BitBucket to GitHub. All git history is reset from this point on
