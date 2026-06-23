class DropTrgmIndexFromAudits < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_audits_on_audited_changes_trgm'.freeze

  def up
    return unless index_present?

    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
  end

  def down
    return if index_present?

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME}
        ON audits USING gin (audited_changes gin_trgm_ops)
    SQL
  end

  private

  def index_present?
    result = ActiveRecord::Base.connection.select_value(
      "SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = '#{INDEX_NAME}'"
    )
    result.present?
  end
end
