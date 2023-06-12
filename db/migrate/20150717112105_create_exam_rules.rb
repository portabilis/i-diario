class CreateExamRules < ActiveRecord::Migration[4.2]
  def change
    create_table :exam_rules do |t|
      t.string :api_code
      t.string :score_type
      t.string :frequency_type
      t.string :opinion_type
      t.string :frequency_type
      t.string :rounding_table_api_code
      t.references :rounding_table, index: true, foreign_key: true

      t.timestamps
    end
  end
end
