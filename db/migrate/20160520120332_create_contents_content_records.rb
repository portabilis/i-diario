class CreateContentsContentRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :contents_content_records do |t|
      t.integer :content_record_id, null: false, index: true
      t.integer :content_id, null: false, index: true
    end
    add_foreign_key :contents_content_records, :content_records
    add_foreign_key :contents_content_records, :contents
  end
end
