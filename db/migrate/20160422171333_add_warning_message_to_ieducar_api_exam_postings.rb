class AddWarningMessageToIeducarApiExamPostings < ActiveRecord::Migration[4.2]
  def change
    add_column :ieducar_api_exam_postings, :warning_message, :string, array: true, default: []
  end
end
