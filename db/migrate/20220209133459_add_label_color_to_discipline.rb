class AddLabelColorToDiscipline < ActiveRecord::Migration[4.2]
  def change
    add_column :disciplines, :label_color, :string
  end
end
