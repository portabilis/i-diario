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

      grade = grade(classroom_record.serie_id)

      next if grade.blank?

      Classroom.with_discarded.find_or_initialize_by(api_code: classroom_record.id).tap do |classroom|
        classroom.description = classroom_record.nome
        classroom.unity = unity
        classroom.unity_code = classroom_record.escola_id
        classroom.period = classroom_record.turno_id
        classroom.grade = grade
        classroom.year = classroom_record.ano
        classroom.exam_rule_id = exam_rule(classroom_record.regra_avaliacao_id).try(:id)

        if classroom.persisted? && classroom.period_changed? && classroom.period_was.present?
          update_period_dependents(classroom.id, classroom.period_was, classroom.period)
        end

        classroom.save! if classroom.changed?

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
end
