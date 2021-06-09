Sequel.migration do
  up do
    run "CREATE TABLE `runners` (
      `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
      `extension_id` int(11) unsigned NOT NULL,
      `name` varchar(256) NOT NULL DEFAULT '',
      `namespace` varchar(256) NOT NULL DEFAULT '',
      `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
      `queue` varchar(256) DEFAULT NULL,
      `uri` varchar(256) DEFAULT NULL,
      `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      CONSTRAINT `runner_extension_id` FOREIGN KEY (`extension_id`) REFERENCES `extensions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
  end

  down do
    drop_table :runners
  end
end
