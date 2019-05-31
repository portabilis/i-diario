class ClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_classrooms(
      HashDecorator.new(
        api.fetch(
          escola_id: unity_api_code,
          ano: year
        )['turmas']
      )
    )
  end

  private

  def api_class
    IeducarApi::Classrooms
  end

  def update_classrooms(classrooms)
    classrooms.each do |classroom_record|
      unity = unity(classroom_record.escola_id)

      next if unity.blank?

      grade = grade(classroom_record.serie_id)

      next if grade.blank?

      Classroom.with_discarded.find_or_initialize_by(api_code: classroom_record.id).tap do |classroom|
        exam_rule = exam_rule(classroom_record.regra_avaliacao_id)
        classroom.description = classroom_record.nome
        classroom.unity = unity
        classroom.unity_code = classroom_record.escola_id
        classroom.period = classroom_record.turno_id
        classroom.grade = grade
        classroom.year = classroom_record.ano
        classroom.exam_rule = exam_rule if exam_rule.present?
        classroom.save! if classroom.changed?

        if exam_rule.present?
          update_differentiated_exam_rules(exam_rule, classroom_record.regra_avaliacao_diferenciada_id)
        end

        classroom.discard_or_undiscard(classroom_record.deleted_at.present?)
      end
    end
  end

  def update_differentiated_exam_rules(exam_rule, regra_avaliacao_diferenciada_id)
    differentiated_exam_rule_id = exam_rule(regra_avaliacao_diferenciada_id)
    exam_rule.differentiated_exam_rule_id = differentiated_exam_rule_id
    exam_rule.save! if exam_rule.changed?
  end
end
