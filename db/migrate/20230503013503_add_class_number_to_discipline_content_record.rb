class AddClassNumberToDisciplineContentRecord < ActiveRecord::Migration
  def up
    add_column :discipline_content_records, :class_number, :integer, default: 0
  end

  def down
    remove_column :discipline_content_records, :class_number
  end
end
