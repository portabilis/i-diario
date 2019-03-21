class CoursesGradesClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_courses(
      HashDecorator.new(
        api.fetch(
          escola_id: unities_code,
          get_series: true,
          get_turmas: true
        )['cursos']
      )
    )
  end

  protected

  def api_class
    IeducarApi::Lectures
  end

  def update_courses(courses)
    ActiveRecord::Base.transaction do
      courses.each do |course_record|
        Course.find_or_initialize_by(api_code: course_record.id).tap do |course|
          course.description = course_record.nome
          course.save! if course.changed?

          update_grades(course, course_record.series)
        end
      end
    end
  end

  def update_grades(course, grades)
    grades.each do |grade_record|
      Grade.find_or_initialize_by(api_code: grade_record.id).tap do |grade|
        grade.description = grade_record.nome
        grade.course = course
        grade.save! if grade.changed?

        update_classrooms(grade, grade_record.turmas) if grade_record.turmas
      end
    end
  end

  def update_classrooms(grade, classrooms)
    classrooms.each do |classroom_record|
      Classroom.find_or_initialize_by(api_code: classroom_record.cod_turma).tap do |classroom|
        classroom.description = classroom_record.nm_turma
        classroom.unity_id = unity(classroom_record.escola_id).try(:id)
        classroom.unity_code = classroom_record.escola_id
        classroom.period = classroom_record.turma_turno_id
        classroom.grade = grade
        classroom.year = classroom_record.ano
        classroom.save! if classroom.changed?

        classroom.discard_or_undiscard(classroom_record.deleted_at.present?)
      end
    end
  end

  def unities_code
    Unity.with_api_code
         .collect(&:api_code)
         .uniq
         .flatten
  end

  def unity(unity_id)
    @unities ||= {}
    @unities[unity_id] ||= ExamRule.find_by(api_code: unity_id)
  end
end
