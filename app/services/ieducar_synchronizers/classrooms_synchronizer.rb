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
        classroom.save! if classroom.changed?

        if (classroom_calendar = outdated_classroom_calendar?(unity.id, classroom_record.id).presence)
          classroom_calendar.update(classroom_id: classroom.id)
        end

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

  def outdated_classroom_calendar?(unity_id, classroom_api_code)
    school_calendar_ids = school_calendar_ids(unity_id)

    SchoolCalendarClassroom.find_by(
      school_calendar_id: school_calendar_ids,
      classroom_id: nil,
      classroom_api_code: classroom_api_code
    )
  end

  def school_calendar_ids(unity_id)
    @school_calendar_ids ||= SchoolCalendar.by_unity_id(unity_id).pluck(:id)
  end
end
