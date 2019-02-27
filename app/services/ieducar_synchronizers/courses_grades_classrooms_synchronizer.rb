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

  def api
    IeducarApi::Lectures.new(synchronization.to_api)
  end

  def update_courses(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        course = Course.find_by(api_code: record.id)

        if course.present?
          course.update(
            description: record.nome
          )
        else
          course = Course.create!(
            api_code: record.id,
            description: record.nome
          )
        end

        update_grades(course, record.series)
      end
    end
  end

  def update_grades(course, collection)
    collection.each do |record|
      grade = Grade.find_by(api_code: record.id)

      if grade.present?
        grade.update(
          description: record.nome,
          course: course
        )
      else
        grade = Grade.create!(
          api_code: record.id,
          description: record.nome,
          course: course
        )
      end

      update_classrooms(grade, record.turmas) if record.turmas
    end
  end

  def update_classrooms(grade, collection)
    collection.each do |record|
      classroom = Classroom.find_by(api_code: record.cod_turma)
      unity = Unity.find_by(api_code: record.escola_id)

      if classroom.present?
        classroom.update(
          description: record.nm_turma,
          unity_id: unity.try(:id),
          unity_code: record.escola_id,
          period: record.turma_turno_id,
          grade: grade
        )
      else
        Classroom.create!(
          api_code: record.cod_turma,
          description: record.nm_turma,
          unity_id: unity.try(:id),
          unity_code: record.escola_id,
          period: record.turma_turno_id,
          grade: grade,
          year: record.ano
        )
      end
    end
  end

  def unities
    Unity.with_api_code.collect(&:api_code).uniq.flatten
  end
end
