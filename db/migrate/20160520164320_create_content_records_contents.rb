class CreateContentRecordsContents < ActiveRecord::Migration[4.2]
  def change
    create_table :content_records_contents do |t|
      t.integer :content_record_id, null: false, index: true
      t.integer :content_id, null: false, index: true
    end
    add_foreign_key :content_records_contents, :content_records
    add_foreign_key :content_records_contents, :contents
  end
end
