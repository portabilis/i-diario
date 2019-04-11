class StudentEnrollmentDependenceSynchronizer < BaseSynchronizer
  def synchronize!
    update_dependences(
      HashDecorator.new(
        api.fetch(ano: years.first)['matriculas']
      )
    )
  end

  def self.synchronize_in_batch!(params)
    super do
      params[:years].each do |year|
        new(
          synchronization: params[:synchronization],
          worker_batch: params[:worker_batch],
          years: [year],
          unity_api_code: params[:unity_api_code],
          entity_id: params[:entity_id]
        ).synchronize!
      end
    end
  end

  private

  def api_class
    IeducarApi::StudentEnrollmentDependences
  end

  def update_dependences(dependences)
    dependences.each do |dependence_record|
      StudentEnrollmentDependence.find_or_initialize_by(api_code: dependence_record.id).tap do |dependence|
        dependence.student_enrollment_id = student_enrollment(dependence_record.matricula_id).try(:id)
        dependence.student_enrollment_code = dependence_record.matricula_id
        dependence.discipline_id = discipline(dependence_record.disciplina_id).try(:id)
        dependence.discipline_code = dependence_record.disciplina_id
        dependence.save! if dependence.changed?
      end
    end
  end
end
