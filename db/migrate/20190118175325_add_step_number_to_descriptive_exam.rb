class AddStepNumberToDescriptiveExam < ActiveRecord::Migration
  def change
    add_column :descriptive_exams, :step_number, :integer, null: false, default: 0
  end
end
