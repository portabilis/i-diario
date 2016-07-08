class AddCurrentDisciplineIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_discipline_id, :integer
  end
end
