class AddLabelColorToClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :classrooms, :label_color, :string
  end
end
