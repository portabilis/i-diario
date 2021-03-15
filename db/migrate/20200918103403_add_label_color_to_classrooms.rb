class AddLabelColorToClassrooms < ActiveRecord::Migration
  def change
    add_column :classrooms, :label_color, :string
  end
end
