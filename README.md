Legion::Data
=====

Legion::Data is a gem for the LegionIO framework to use persistent storage. Currently only MySQL is supported

Supported Ruby versions and implementations
------------------------------------------------

Legion::Json should work identically on:

* Ruby 2.5+


Installation and Usage
------------------------

You can verify your installation using this piece of code:

```bash
gem install legion-data
```

```ruby
require 'legion/data'

Legion::Data.setup
Legion::Data.connected? # => true
Legion::Data::Model::Extension.all # Sequel::Dataset
```

Settings
----------

```json
{
  "connected": false,
  "cache": {
    "connected": false,
    "auto_enable": null,
    "ttl": 60
  },
  "connection": {
    "log": false,
    "log_connection_info": false,
    "log_warn_duration": 1,
    "log_warn_duration": "debug",
    "max_connections": 10,
    "preconnect": false
  },
  "creds": {
    "username": "legion",
    "password": "legion",
    "database": "legionio",
    "host": "127.0.0.1",
    "port": 3306
  },
  "migrations": {
    "continue_on_fail": false,
    "auto_migrate": true,
    "ran": false,
    "version": null
  },
  "models": {
    "continue_on_load_fail": false,
    "autoload": true
  },
  "connect_on_start": true
}
```

Authors
----------

* [Matthew Iverson](https://github.com/Esity) - current maintainer