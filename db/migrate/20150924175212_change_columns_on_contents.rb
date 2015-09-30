class ChangeColumnsOnContents < ActiveRecord::Migration
  def change
    change_column :contents, :description, :text, null: true

    execute <<-SQL
      UPDATE contents SET theme = description;
      UPDATE contents SET description = '';
    SQL

    change_column :contents, :theme, :text, null: false
  end
end
