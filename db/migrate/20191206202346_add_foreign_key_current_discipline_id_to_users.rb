class AddForeignKeyCurrentDisciplineIdToUsers < ActiveRecord::Migration
  def change
    add_foreign_key :users, :disciplines, column: :current_discipline_id
  end
end
