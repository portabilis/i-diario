class GradeExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_grade_exam_rules(
      HashDecorator.new(
        api.fetch(
          ano: year,
          ignore_modified: true
        )['regras']
      )
    )
  end

  private

  def api_class
    IeducarApi::GradeExamRules
  end

  def update_grade_exam_rules(grade_exam_rules)
    grade_exam_rules.each do |grade_exam_rule|
      grade = grade(grade_exam_rule.serie_id)

      next if grade.blank?

      exam_rule = exam_rule(grade_exam_rule.regra_avaliacao_id)
      differentiated_exam_rule = exam_rule(grade_exam_rule.regra_avaliacao_diferenciada_id)
      classroom_ids = grade.classrooms_grades.pluck(:classroom_id)
      classrooms_grades = Classroom.with_discarded.by_year(year).where(id: classroom_ids).map(&:classrooms_grades)

      classrooms_grades.each do |classroom_grade_record|
        classroom_grade_record.each do |classroom_grade|
          unity = unity(classroom_grade.classroom.unity_code)

          current_exam_rule = differentiated_exam_rule if unity.uses_differentiated_exam_rule?
          current_exam_rule ||= exam_rule
          classroom_grade.exam_rule = current_exam_rule

          classroom_grade.save! if classroom_grade.changed?
        end
      end
    end
  end
end
