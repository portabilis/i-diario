class AddRequestUuidToAudits < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def self.up
    add_column :audits, :request_uuid, :string
    add_index :audits, :request_uuid, algorithm: :concurrently
  end

  def self.down
    remove_column :audits, :request_uuid
  end
end
