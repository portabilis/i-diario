class CreateComplementaryExamSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :complementary_exam_settings do |t|
      t.string :description, null: false
      t.string :initials, null: false
      t.string :affected_score, null: false
      t.string :calculation_type, null: false
      t.integer :maximum_score, null: false
      t.integer :number_of_decimal_places, null: false

      t.timestamps
    end
  end
end
