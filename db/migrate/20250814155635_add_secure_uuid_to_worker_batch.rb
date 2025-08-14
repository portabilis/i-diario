class AddSecureUuidToWorkerBatch < ActiveRecord::Migration[5.0]
  def up
    # Adiciona extensão pgcrypto para gerar UUIDs seguros
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    # Adiciona coluna UUID com valor padrão gerado pelo PostgreSQL
    add_column :worker_batches, :secure_uuid, :uuid, default: 'gen_random_uuid()', null: false

    # Gera UUIDs para registros existentes (se houver)
    execute <<-SQL
      UPDATE worker_batches
      SET secure_uuid = gen_random_uuid()
      WHERE secure_uuid IS NULL;
    SQL
  end

  def down
    remove_column :worker_batches, :secure_uuid
  end
end