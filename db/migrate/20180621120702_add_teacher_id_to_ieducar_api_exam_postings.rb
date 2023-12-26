class AddTeacherIdToIeducarApiExamPostings < ActiveRecord::Migration[4.2]
  def change
    add_column :ieducar_api_exam_postings, :teacher_id, :integer
    add_index :ieducar_api_exam_postings, :teacher_id
  end
end
