class StudentEnrollmentDependenceSynchronizer < BaseSynchronizer
  def synchronize!
    ActiveRecord::Base.transaction do
      years.each do |year|
        update_dependences(
          HashDecorator.new(
            api.fetch(ano: year)['matriculas']
          )
        )
      end
    end
  end

  protected

  def api_class
    IeducarApi::StudentEnrollmentDependences
  end

  def update_dependences(dependences)
    dependences.each do |dependence_record|
      StudentEnrollmentDependence.find_or_initialize_by(api_code: dependence_record.id).tap do |dependence|
        dependence.student_enrollment_id = student_enrollment(record.matricula_id).try(:id)
        dependence.student_enrollment_code = record.matricula_id
        dependence.discipline_id = discipline(record.disciplina_id).try(:id)
        dependence.discipline_code = record.disciplina_id
        dependence.save! if dependence.changed?
      end
    end
  end

  def student_enrollment(student_enrollment_id)
    @student_enrollments ||= {}
    @student_enrollments[student_enrollment_id] ||= StudentEnrollment.find_by(api_code: student_enrollment_id)
  end

  def discipline(discipline_id)
    @disciplines ||= {}
    @disciplines[discipline_id] ||= Discipline.find_by(api_code: discipline_id)
  end
end
