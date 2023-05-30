class CreateSpecificSteps < ActiveRecord::Migration[4.2]
  def change
    create_table :specific_steps do |t|
      t.references :classroom, index: true, foreign_key: true
      t.references :discipline, index: true, foreign_key: true
      t.string :used_steps

      t.timestamps null: false
    end
  end
end
