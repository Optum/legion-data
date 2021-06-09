Sequel.migration do
  up do
    run "CREATE TABLE `extensions` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
      `name` varchar(128) NOT NULL,
      `namespace` varchar(128) NOT NULL DEFAULT '',
      `exchange` varchar(255) DEFAULT NULL,
      `uri` varchar(256) DEFAULT NULL,
      `schema_version` int(11) unsigned NOT NULL DEFAULT 0,
      `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
      `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      UNIQUE KEY `name_namespace` (`name`,`namespace`),
      KEY `active` (`active`),
      KEY `name` (`name`),
      KEY `namespace` (`namespace`),
      key `schema_version` (`schema_version`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
  end

  down do
    drop_table :extensions
  end
end
