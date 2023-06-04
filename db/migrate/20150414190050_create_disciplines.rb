class CreateDisciplines < ActiveRecord::Migration[4.2]
  def change
    create_table :disciplines do |t|
      t.string :api_code, index: true, null: false
      t.string :description, null: false

      t.timestamps
    end
  end
end
