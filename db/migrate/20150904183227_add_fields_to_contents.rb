class AddFieldsToContents < ActiveRecord::Migration[4.2]
  def change
    add_column :contents, :theme, :text
    add_column :contents, :goals, :text
    add_column :contents, :means, :text
    add_column :contents, :evaluation, :text
    add_column :contents, :bibliography, :text
    add_column :contents, :classes, :integer, array: true, default: []
    add_reference :contents, :knowledge_area, index: true
    change_column :contents, :discipline_id, :integer, null: true

    execute <<-SQL
      UPDATE contents SET classes = array(SELECT a.class_number FROM contents a WHERE a.id = contents.id);
    SQL

    remove_column :contents, :class_number
  end
end