class ClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_classrooms(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code,
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

      grades = []
      classroom_record.series_regras.select { |serie| grades << serie.serie_id }
      grade = grade(grades.compact.first)

      next if grade.blank?

      next if classroom_record.nome.nil?

      Classroom.with_discarded.find_or_initialize_by(api_code: classroom_record.id).tap do |classroom|
        old_name = classroom.description.try(:strip)
        new_name = classroom_record.nome.try(:strip)
        classroom.description = new_name
        classroom.unity = unity
        classroom.unity_code = classroom_record.escola_id
        classroom.period = classroom_record.turno_id
        classroom.year = classroom_record.ano
        classroom_record.series_regras.each do |grade_exam_rule|
          grade = grade(grade_exam_rule.serie_id)
          exam_rule = exam_rule(grade_exam_rule.regra_avaliacao_id)

          next if grade.blank? || exam_rule.blank?

          classroom.classrooms_grades.find_or_initialize_by(grade_id: grade.id, exam_rule_id: exam_rule.id)
        end

        if classroom.persisted? && classroom.period_changed? && classroom.period_was.present?
          update_period_dependents(classroom.id, classroom.period_was, classroom.period)
        end

        classroom.save!

        update_label(classroom.id, new_name) if old_name != new_name

        classroom.discard_or_undiscard(classroom_record.deleted_at.present?)

        remove_current_classroom_id_in_user_selectors(classroom.id) if classroom_record.deleted_at.present?
      end
    end
  end

  def remove_current_classroom_id_in_user_selectors(classroom_id)
    Classroom.with_discarded.find_by(id: classroom_id).users.each do |user|
      user.update(current_classroom_id: nil, assumed_teacher_id: nil)
    end
  end

  def update_period_dependents(classroom_id, old_period, new_period)
    PeriodUpdaterWorker.perform_in(1.second, entity_id, classroom_id, old_period, new_period)
  end

  def update_label(classroom_id, new_name)
    label = Label.find_by(labelable_id: classroom_id)
    return if label.nil?

    label.name = new_name
    label.save!
  end
end
