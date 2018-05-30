class AddFullErrorMessageToIeducarApiExamPostings < ActiveRecord::Migration
  def change
    add_column :ieducar_api_exam_postings, :full_error_message, :string
  end
end
