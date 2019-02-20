class SpecificStepClassroomsSynchronizer
  def synchronize!
    specific_step_classrooms_api.each do |turma|
      classroom_id = Classroom.find_by(api_code: turma['turma_id']).try(:id)

      SpecificStepsSynchronizerWorker.new.perform(
        entity.id,
        synchronization.id,
        worker_batch.id,
        classroom_id,
        turma['turma_id']
      )
    end
  end

  private

  def specific_step_classrooms_api
    @specific_step_classrooms_api ||= IeducarApi::SpecificStepClassrooms.new(
      IeducarApiSynchronization.find(synchronization_id).to_api
    ).fetch['turmas']
  end
end
