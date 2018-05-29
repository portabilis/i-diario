class AddActiveToTeachers < ActiveRecord::Migration
  def change
    add_column :teachers, :active, :boolean, default: true, null: false
  end
end
