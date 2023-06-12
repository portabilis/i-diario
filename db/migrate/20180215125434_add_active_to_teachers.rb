class AddActiveToTeachers < ActiveRecord::Migration[4.2]
  def change
    add_column :teachers, :active, :boolean, default: true, null: false
  end
end
