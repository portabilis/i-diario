class CoursesGradesClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      api.fetch(
        escola_id: unities,
        get_series: true,
        get_turmas: true
      )['cursos']
    )

    finish_worker
  end

  protected

  def api
    IeducarApi::Lectures.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        course_record = HashDecorator.new(record)
        course = Course.find_by(api_code: course_record.id)

        if course.present?
          course.update(
            description: course_record.nome
          )
        else
          course = Course.create!(
            api_code: course_record.id,
            description: course_record.nome
          )
        end

        update_grades(course, course_record.series)
      end
    end
  end

  def update_grades(course, collection)
    collection.each do |grade_record|
      grade = Grade.find_by(api_code: grade_record.id)

      if grade.present?
        grade.update(
          description: grade_record.nome,
          course: course
        )
      else
        grade = Grade.create!(
          api_code: grade_record.id,
          description: grade_record.nome,
          course: course
        )
      end

      update_classrooms(grade, grade_record.turmas) if grade_record.turmas
    end
  end

  def update_classrooms(grade, collection)
    collection.each do |classroom_record|
      classroom = Classroom.find_by(api_code: classroom_record.cod_turma)
      unity = Unity.find_by(api_code: classroom_record.escola_id)

      if classroom.present?
        classroom.update(
          description: classroom_record.nm_turma,
          unity_id: unity.try(:id),
          unity_code: classroom_record.escola_id,
          period: classroom_record.turma_turno_id,
          grade: grade
        )
      else
        Classroom.create!(
          api_code: classroom_record.cod_turma,
          description: classroom_record.nm_turma,
          unity_id: unity.try(:id),
          unity_code: classroom_record.escola_id,
          period: classroom_record.turma_turno_id,
          grade: grade,
          year: classroom_record.ano
        )
      end
    end
  end

  def unities
    Unity.with_api_code.collect(&:api_code).uniq.flatten
  end
end
