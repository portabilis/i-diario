class AddClassNumberToDisciplineContentRecord < ActiveRecord::Migration
  def change
    add_column :discipline_content_records, :class_number, :integer, default: nil, null: true
  end
end
