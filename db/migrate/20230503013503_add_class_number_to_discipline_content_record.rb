class AddClassNumberToDisciplineContentRecord < ActiveRecord::Migration
  def change
    add_column :discipline_content_records, :class_number, :integer, default: 0
  end
end
