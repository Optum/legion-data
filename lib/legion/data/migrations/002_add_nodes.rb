Sequel.migration do
  up do
    run "CREATE TABLE `nodes` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `name` varchar(128) NOT NULL DEFAULT '',
      `status` varchar(255) NOT NULL DEFAULT 'unknown',
      `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
      `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      UNIQUE KEY `name` (`name`),
      KEY `active` (`active`),
      KEY `status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
  end

  down do
    drop_table :nodes
  end
end
