class CreateSchoolTermTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :school_term_types do |t|
      t.string :description, null: false
      t.integer :steps_number, null: false

      t.timestamps
    end
  end
end
