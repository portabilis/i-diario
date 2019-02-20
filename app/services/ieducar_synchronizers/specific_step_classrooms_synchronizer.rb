class SpecificStepClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    specific_step_classrooms_api.each do |turma|
      classroom_id = Classroom.find_by(api_code: turma['turma_id']).try(:id)

      SpecificStepsSynchronizer.synchronize!(
        synchronization,
        worker_batch,
        classroom_id,
        turma['turma_id']
      )
    end
  end

  private

  def specific_step_classrooms_api
    @specific_step_classrooms_api ||= IeducarApi::SpecificStepClassrooms.new(
      synchronization.to_api
    ).fetch['turmas']
  end
end
