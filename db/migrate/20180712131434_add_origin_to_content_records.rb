class AddOriginToContentRecords < ActiveRecord::Migration[4.2]
  def change
    add_column :content_records, :origin, :string
  end
end
