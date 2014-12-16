class CreateDeficiencies < ActiveRecord::Migration
  def change
    create_table :deficiencies do |t|
      t.string :api_code
      t.string :name

      t.timestamps
    end
    add_index :deficiencies, :name, unique: true
  end
end
