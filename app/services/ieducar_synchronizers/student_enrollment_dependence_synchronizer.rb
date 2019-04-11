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
      student_enrollment_id = student_enrollment(dependence_record.matricula_id).try(:id)
      discipline_id = discipline(dependence_record.disciplina_id).try(:id)

      next if student_enrollment_id.blank? || discipline_id.blank?

      StudentEnrollmentDependence.with_discarded.find_or_initialize_by(
        student_enrollment_id: student_enrollment_id,
        discipline_id: discipline_id
      ).tap do |dependence|
        dependence.student_enrollment_code = dependence_record.matricula_id
        dependence.discipline_code = dependence_record.disciplina_id
        dependence.save! if dependence.changed?

        dependence.discard_or_undiscard(dependence_record.deleted_at.present?)
      end
    end
  end
end
