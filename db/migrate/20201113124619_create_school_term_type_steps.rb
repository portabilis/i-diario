class CreateSchoolTermTypeSteps < ActiveRecord::Migration[4.2]
  def change
    create_table :school_term_type_steps do |t|
      t.references :school_term_type, index: true, null: false, foreign_key: true
      t.integer :step_number

      t.timestamps
    end
  end
end
