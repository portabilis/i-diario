class ChangeColumnDescriptionOnDisciplines < ActiveRecord::Migration
  def change
    change_column :disciplines, :description, :string, limit: 500
  end
end
