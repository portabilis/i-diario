class RemoveTrgmIndexFromAudits < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  def up
    if index_exists?(:audits, name: :index_audits_on_audited_changes_trgm)
      remove_index :audits, name: :index_audits_on_audited_changes_trgm, algorithm: :concurrently
    end
  end
  def down
    unless index_exists?(:audits, name: :index_audits_on_audited_changes_trgm)
      add_index :audits, :audited_changes,
                name: 'index_audits_on_audited_changes_trgm',
                using: :gin,
                opclass: 'gin_trgm_ops',
                algorithm: :concurrently
    end
  end
end