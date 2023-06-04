class DefineJustificationAsNull < ActiveRecord::Migration
  def change
    change_column :absence_justifications, :justification, :text, null: true
  end
end
