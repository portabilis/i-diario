class AddOpinionTypeToDescriptiveExams < ActiveRecord::Migration[4.2]
  def change
    add_column(:descriptive_exams, :opinion_type, :string)
    execute <<-SQL
      update descriptive_exams
      set opinion_type = er.opinion_type
      from classrooms c,exam_rules er
      where c.id = descriptive_exams.classroom_id
      and er.id = c.exam_rule_id
    SQL
    change_column_null(:descriptive_exams, :opinion_type, false)
  end
end
