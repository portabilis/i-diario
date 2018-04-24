class CoursesGradesClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch(escola_id: unities,
                             get_series: true,
                             get_turmas: true)["cursos"]

    finish_worker('CoursesGradesClassroomsSynchronizer')
  end

  protected

  def api
    IeducarApi::Lectures.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        if course = courses.find_by(api_code: record["id"])
          course.update_attribute(:description, record["nome"])
        else
          course = courses.create!(
            api_code: record["id"],
            description: record["nome"]
          )
        end

        update_grades(course, record["series"])
      end
    end
  end

  def update_grades(course, collection)
    collection.each do |record|
      if grade = grades.find_by(api_code: record["id"])
        grade.update(
          description: record["nome"],
          course: course
        )
      else
        grade = grades.create!(
          api_code: record["id"],
          description: record["nome"],
          course: course
        )
      end
      update_classrooms(grade, record['turmas']) if record['turmas']
    end
  end

  def update_classrooms(grade, collection)
    collection.each do |record|
      if classroom = classrooms.find_by(api_code: record["cod_turma"])
        classroom.update(
          description: record["nm_turma"],
          unity_id: Unity.find_by(api_code: record["escola_id"]).try(:id),
          unity_code: record["escola_id"],
          period: record["turma_turno_id"],
          grade: grade
        )
      else
        classroom = classrooms.create!(
          api_code: record["cod_turma"],
          description: record["nm_turma"],
          unity_id: Unity.find_by(api_code: record["escola_id"]).try(:id),
          unity_code: record["escola_id"],
          period: record["turma_turno_id"],
          grade: grade,
          year: record["ano"]
        )
      end
    end
  end

  def unities
    Unity.with_api_code.collect(&:api_code).uniq.flatten
  end

  def courses(klass = Course)
    klass
  end

  def grades(klass = Grade)
    klass
  end

  def classrooms(klass = Classroom)
    klass
  end
end
