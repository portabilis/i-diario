class CoursesGradesClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_courses(
      HashDecorator.new(
        api.fetch(
          escola_id: unities,
          get_series: true,
          get_turmas: true
        )['cursos']
      )
    )

    finish_worker
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
      unity = Unity.find_by(api_code: classroom_record.escola_id)

      Classroom.find_or_initialize_by(api_code: classroom_record.id).tap do |classroom|
        classroom.description = classroom_record.nm_turma
        classroom.unity_id = unity.try(:id)
        classroom.unity_code = classroom_record.escola_id
        classroom.period = classroom_record.turma_turno_id
        classroom.grade = grade
        classroom.year = classroom_record.ano

        classroom.save! if classroom.changed?
      end
    end
  end

  def unities
    Unity.with_api_code
         .collect(&:api_code)
         .uniq
         .flatten
  end
end
