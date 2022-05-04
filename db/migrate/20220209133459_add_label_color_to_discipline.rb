class AddLabelColorToDiscipline < ActiveRecord::Migration
  def change
    add_column :disciplines, :label_color, :string
  end
end
