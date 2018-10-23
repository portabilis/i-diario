class AddApiCodeIndexToDisciplines < ActiveRecord::Migration
  def change
    execute "DROP INDEX index_disciplines_on_api_code IF EXISTS"
    add_index :disciplines, :api_code, unique: true
  end
end
