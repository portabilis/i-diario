class AddTrgmIndexToAuditsAuditedChanges < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    add_index :audits, :audited_changes,
              using: :gin,
              opclass: :gin_trgm_ops,
              algorithm: :concurrently,
              name: 'index_audits_on_audited_changes_trgm'
  end
end