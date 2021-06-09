Sequel.migration do
  up do
    run "CREATE TABLE `functions` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `name` varchar(128) NOT NULL,
      `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
      `runner_id` int(11) unsigned NOT NULL,
      `args` text,
      `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      UNIQUE KEY `runner_id` (`runner_id`,`name`),
      KEY `active` (`active`),
      KEY `namespace` (`runner_id`),
      KEY `name` (`name`),
      CONSTRAINT `function_runner_id` FOREIGN KEY (`runner_id`) REFERENCES `runners` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
  end

  down do
    drop_table :functions
  end
end
