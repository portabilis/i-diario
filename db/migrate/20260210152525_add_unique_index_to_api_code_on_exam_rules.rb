class AddUniqueIndexToApiCodeOnExamRules < ActiveRecord::Migration[5.0]
  def up
    remove_index :exam_rules, :api_code
    add_index :exam_rules, :api_code, unique: true
  end

  def down
    remove_index :exam_rules, :api_code
    add_index :exam_rules, :api_code
  end
end
