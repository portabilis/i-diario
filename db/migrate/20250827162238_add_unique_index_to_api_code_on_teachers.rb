class AddUniqueIndexToApiCodeOnTeachers < ActiveRecord::Migration[5.0]
  def up
    execute "DROP INDEX IF EXISTS index_teachers_on_api_code"

    add_index :teachers, :api_code, unique: true, name: 'index_teachers_on_api_code_unique'
  end

  def down
    execute "DROP INDEX IF EXISTS index_teachers_on_api_code_unique"

    add_index :teachers, :api_code, name: 'index_teachers_on_api_code'
  end
end
