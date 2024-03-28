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
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
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
      classrooms_grades = ClassroomsGrade.by_grade_id(grade.id).by_year(year).by_exam_rule(exam_rule.id)

      classrooms_grades.each do |classroom_grade|
        unity = unity(classroom_grade.classroom.unity_code)

        current_exam_rule = differentiated_exam_rule if unity.try(:uses_differentiated_exam_rule?)
        current_exam_rule ||= exam_rule
        classroom_grade.exam_rule = current_exam_rule

        classroom_grade.save! if classroom_grade.changed?
      end
    end
  end
end
