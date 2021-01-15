class CreateSchoolTermTypes < ActiveRecord::Migration
  def change
    create_table :school_term_types do |t|
      t.string :description, null: false
      t.integer :steps_number, null: false

      t.timestamps
    end
  end
end
