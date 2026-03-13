# legion-data

Persistent database storage for the [LegionIO](https://github.com/LegionIO/LegionIO) framework. Provides database connectivity via Sequel ORM, automatic schema migrations, and data models for extensions, functions, runners, nodes, tasks, and settings.

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

## Usage

```ruby
require 'legion/data'

Legion::Data.setup
Legion::Data.connection # => Sequel::Database
Legion::Data::Model::Extension.all # => Sequel::Dataset
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

## Requirements

- Ruby >= 3.4

## License

Apache-2.0
