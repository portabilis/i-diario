class AddStepNumberToComplementaryExam < ActiveRecord::Migration
  def change
    add_column :complementary_exams, :step_number, :integer, null: false, default: 0
  end
end
