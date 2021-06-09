Sequel.migration do
  up do
    run "CREATE TABLE `settings` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `key` varchar(128) NOT NULL,
      `value` varchar(256) NOT NULL,
      `encrypted` tinyint(1) unsigned NOT NULL DEFAULT '0',
      `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      UNIQUE KEY `key` (`key`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
  end

  down do
    drop_table :settings
  end
end
