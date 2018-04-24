class SpecificStepsSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    specific_step_classrooms_api.fetch['turmas'].each do |turma|
      classroom_id = Classroom.find_by_api_code(turma['turma_id']).try(:id)

      if classroom_id
        specific_steps_api.fetch(turma_id: turma['turma_id'])['etapas'].each do |specific_step|
          update_or_create_specific_step(classroom_id, specific_step['disciplina_id'], specific_step['etapas_utilizadas'])
        end
      end
    end
  end

  protected

  attr_accessor :synchronization

  def specific_steps_api
    @specific_steps ||= IeducarApi::SpecificSteps.new(synchronization.to_api)
  end

  def specific_step_classrooms_api
    @specific_step_classrooms ||= IeducarApi::SpecificStepClassrooms.new(synchronization.to_api)
  end

  def update_or_create_specific_step(classroom_id, discipline_api_id, used_steps)
    ActiveRecord::Base.transaction do
      discipline_id = Discipline.find_by_api_code(discipline_api_id).try(:id)

      if discipline_id
        if specific_step = SpecificStep.find_by(classroom_id: classroom_id, discipline_id: discipline_id)
          specific_step.update_column(:used_steps, used_steps)
        else
          SpecificStep.create!(
            classroom_id: classroom_id,
            discipline_id: discipline_id,
            used_steps: used_steps
          )
        end
      end
    end
  end
end
