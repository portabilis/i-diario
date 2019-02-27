class StudentEnrollmentDependenceSynchronizer < BaseSynchronizer
  def synchronize!
    ActiveRecord::Base.transaction do
      destroy_records

      years.each do |year|
        create_records(
          HashDecorator.new(
            api.fetch(ano: year)['matriculas']
          )
        )
      end
    end

    finish_worker
  end

  protected

  def api
    IeducarApi::StudentEnrollmentDependences.new(synchronization.to_api)
  end

  def create_records(collection)
    return if collection.blank?

    collection.each do |record|
      StudentEnrollmentDependence.create!(
        student_enrollment_id: StudentEnrollment.find_by(api_code: record.matricula_id).try(:id),
        student_enrollment_code: record.matricula_id,
        discipline_id: Discipline.find_by(api_code: record.disciplina_id).try(:id),
        discipline_code: record.disciplina_id
      )
    end
  end

  def destroy_records
    StudentEnrollmentDependence.destroy_all
  end
end
