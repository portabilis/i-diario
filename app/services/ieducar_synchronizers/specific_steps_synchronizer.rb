class SpecificStepsSynchronizer < BaseSynchronizer
  def synchronize!
    update_specific_steps(
      HashDecorator.new(
        api.fetch['etapas']
      )
    )

    finish_worker
  end

  protected

  def api_class
    IeducarApi::SpecificSteps
  end

  def update_specific_steps(specific_steps)
    ActiveRecord::Base.transaction do
      specific_steps.each do |specific_step_record|
        SpecificStep.find_or_initialize_by(
          classroom_id: classroom(specific_step_record.turma_id).try(:id),
          discipline_id: discipline(specific_step_record.disciplina_id).try(:id)
        ).tap do |specific_step|
          specific_step.used_steps = specific_step_record.etapas_utilizadas
          specific_step.save! if specific_step.changed?

          specific_step.discard_or_undiscard(specific_step_record.deleted_at.present?)
        end
      end
    end
  end

  def classroom(classroom_id)
    @classrooms ||= {}
    @classrooms[classroom_id] ||= Classroom.find_by(api_code: classroom_id)
  end

  def discipline(discipline_id)
    @disciplines ||= {}
    @disciplines[discipline_id] ||= Discipline.find_by(api_code: discipline_id)
  end
end
