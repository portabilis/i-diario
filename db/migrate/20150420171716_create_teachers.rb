class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.string :api_code, index: true, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
