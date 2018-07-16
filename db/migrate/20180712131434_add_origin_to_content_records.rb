class AddOriginToContentRecords < ActiveRecord::Migration
  def change
    add_column :content_records, :origin, :string
  end
end
