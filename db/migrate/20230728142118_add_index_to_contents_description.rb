class AddIndexToContentsDescription < ActiveRecord::Migration[5.0]
  def up
    #  O índice GIN usando a extensão "pg_trgm" permitirá consultas mais eficientes e rápidas em pesquisas textuais
    #  ou em arrays complexos armazenados na coluna description.
    execute "CREATE INDEX index_contents_on_description_gin_trgm ON contents USING gin (description gin_trgm_ops);"
  end

  def down
    # Remove the GIN index on 'description' column
    remove_index :contents, name: :index_contents_on_description_gin_trgm
  end
end
