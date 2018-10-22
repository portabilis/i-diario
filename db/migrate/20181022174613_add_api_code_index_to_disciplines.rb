class AddApiCodeIndexToDisciplines < ActiveRecord::Migration
  def change
    remove_index :disciplines, :api_code
    add_index :disciplines, :api_code, unique: true
  end
end
