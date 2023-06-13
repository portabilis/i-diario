class CreateStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :students do |t|
      t.string :api_code
      t.string :name
      t.boolean :api, default: false

      t.timestamps
    end
    add_index :students, :api_code, unique: true
  end
end
