class CreateRecoveryExamRules < ActiveRecord::Migration[4.2]
  def change
    create_table :recovery_exam_rules do |t|
      t.string :api_code, index: true, null: false
      t.string :description, null: false
      t.references :exam_rule, index: true, null: false
      t.integer :steps, array: true, default: []
      t.decimal :average, null: false
      t.decimal :maximum_score, null: false

      t.timestamps
    end

    add_foreign_key :recovery_exam_rules, :exam_rules
  end
end

