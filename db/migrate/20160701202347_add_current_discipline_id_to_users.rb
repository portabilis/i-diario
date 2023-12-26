class AddCurrentDisciplineIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_discipline_id, :integer
  end
end
