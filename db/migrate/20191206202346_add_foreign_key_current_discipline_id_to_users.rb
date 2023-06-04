class AddForeignKeyCurrentDisciplineIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :users, :disciplines, column: :current_discipline_id
  end
end
