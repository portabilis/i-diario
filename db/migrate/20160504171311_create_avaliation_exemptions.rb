class CreateAvaliationExemptions < ActiveRecord::Migration[4.2]
  def change
    create_table :avaliation_exemptions do |t|
      t.references :avaliation, index: true, foreign_key: true
      t.references :student, index: true, foreign_key: true
      t.text :reason

      t.timestamps null: false
    end
  end
end
