class SpecificStepsSynchronizer < BaseSynchronizer
  def synchronize!
    update_specific_steps(
      HashDecorator.new(
        api.fetch(
          ano: year,
          escola: unity_api_code
        )['etapas']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  USE_SPECIFIC_STEP = 1

  def api_class
    IeducarApi::SpecificSteps
  end

  def update_specific_steps(specific_steps)
    specific_steps.each do |specific_step_record|
      SpecificStep.with_discarded.find_or_initialize_by(
        classroom_id: classroom(specific_step_record.turma_id).try(:id),
        discipline_id: discipline(specific_step_record.disciplina_id).try(:id)
      ).tap do |specific_step|
        specific_step.used_steps = specific_step_record.etapas_utilizadas
        specific_step.save! if specific_step.changed?

        discard_specific_step = specific_step_record.deleted_at.present? ||
                                specific_step_record.etapas_especificas != USE_SPECIFIC_STEP
        specific_step.discard_or_undiscard(discard_specific_step)
      end
    end
  end
end
