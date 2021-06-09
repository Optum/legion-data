Sequel.migration do
  up do
    run "CREATE TABLE `tasks` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `relationship_id` int(11) unsigned DEFAULT NULL,
      `function_id` int(11) unsigned DEFAULT NULL,
      `status` varchar(255) NOT NULL,
      `parent_id` int(11) unsigned DEFAULT NULL,
      `master_id` int(11) unsigned DEFAULT NULL,
      `function_args` text,
      `results` text,
      `payload` text,
      `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `status` (`status`),
      KEY `parent_id` (`parent_id`),
      KEY `master_id` (`master_id`),
      KEY `relationship_id` (`relationship_id`),
      KEY `function_id` (`function_id`),
      CONSTRAINT `parent_id` FOREIGN KEY (`parent_id`) REFERENCES `tasks` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
      CONSTRAINT `master_id` FOREIGN KEY (`master_id`) REFERENCES `tasks` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
  end

  down do
    drop_table :tasks
  end
end
