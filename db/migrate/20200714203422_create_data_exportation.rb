class CreateDataExportation < ActiveRecord::Migration[4.2]
  def change
    create_table :data_exportations do |t|
      t.string :backup_type, null: false
      t.string :backup_file
      t.string :backup_status, null: false
      t.string :error_message

      t.timestamps null: false
    end
  end
end
