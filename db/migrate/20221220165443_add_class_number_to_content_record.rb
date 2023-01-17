class AddClassNumberToContentRecord < ActiveRecord::Migration
  def change
    add_column :content_records, :class_number, :integer, default: 0
  end
end
