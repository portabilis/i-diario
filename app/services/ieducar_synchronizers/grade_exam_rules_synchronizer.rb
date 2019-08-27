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

      grade.classrooms.with_discarded.by_year(year).each do |classroom_record|
        classroom_record.tap do |classroom|
          unity = unity(classroom.unity_code)
          current_exam_rule = differentiated_exam_rule if unity.uses_differentiated_exam_rule?
          current_exam_rule ||= exam_rule
          classroom.exam_rule = current_exam_rule
          classroom.save! if classroom.changed?
        end
      end
    end
  end
end
