class SpecificStepClassroomsSynchronizer
  def self.synchronize!(entity_id, synchronization_id, worker_batch_id)
    new(entity_id, synchronization_id, worker_batch_id).synchronize!
  end

  def initialize(entity_id, synchronization_id, worker_batch_id)
    self.entity_id = entity_id
    self.synchronization_id = synchronization_id
    self.worker_batch_id = worker_batch_id
  end

  def synchronize!
    specific_step_classrooms_api.each do |turma|
      classroom_id = Classroom.find_by_api_code(turma['turma_id']).try(:id)

      if classroom_id
        SpecificStepsSynchronizerWorker.perform_async(entity_id, synchronization_id, worker_batch_id, classroom_id, turma['turma_id'])
      end
    end

    specific_step_classrooms_api.count
  end

  private

  attr_accessor :entity_id, :synchronization_id, :worker_batch_id

  def specific_step_classrooms_api
    @specific_step_classrooms ||= IeducarApi::SpecificStepClassrooms.new(IeducarApiSynchronization.find(synchronization_id).to_api).fetch['turmas']
  end
end
