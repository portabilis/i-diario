class ChangeColumnDescriptionOnDisciplines < ActiveRecord::Migration[4.2]
  def change
    change_column :disciplines, :description, :string, limit: 500
  end
end
