require 'sequel/extensions/migration'

Sequel.migration do
  up do
    run 'ALTER TABLE `schema_info` ADD `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER `version`;'
    run 'ALTER TABLE `schema_info` ADD `updated_at` TIMESTAMP  NULL  ON UPDATE CURRENT_TIMESTAMP  AFTER `created_at`;'
    run 'ALTER TABLE `schema_info` ADD `catalog` VARCHAR(255)  NULL  DEFAULT NULL  AFTER `version`;'
  end

  down do
    alter_table(:schema_info) do
      drop_column :catalog
      drop_column :updated_at
      drop_column :created_at
    end
  end
end
