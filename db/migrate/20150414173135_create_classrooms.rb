class CreateClassrooms < ActiveRecord::Migration[4.2]
  def change
    create_table :classrooms do |t|
      t.string :api_code
      t.string :unity_code
      t.integer :unity_id
      t.integer :year
      t.string :description

      t.timestamps
    end

    add_index :classrooms, :api_code, unique: true

    add_index :classrooms, :unity_id
    add_foreign_key :classrooms, :unities
  end
end
