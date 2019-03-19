class SpecificStepsSynchronizer < BaseSynchronizer
  def self.synchronize!(synchronization, worker_batch, classroom_id, api_classroom_id)
    new(synchronization, worker_batch, classroom_id, api_classroom_id).synchronize!
  end

  def initialize(synchronization, worker_batch, classroom_id, api_classroom_id)
    self.synchronization = synchronization
    self.worker_batch = worker_batch
    self.classroom_id = classroom_id
    self.api_classroom_id = api_classroom_id
  end

  def synchronize!
    if classroom_id
      specific_steps_api.fetch(turma_id: api_classroom_id)['etapas'].each do |specific_step|
        update_or_create_specific_step(
          classroom_id,
          specific_step['disciplina_id'],
          specific_step['etapas_utilizadas'],
          Time.zone.parse(specific_step['updated_at'])
        )
      end
    end
  end

  protected

  attr_accessor :classroom_id, :api_classroom_id

  def worker_name
    "#{self.class}-#{api_classroom_id}"
  end

  def specific_steps_api
    IeducarApi::SpecificSteps.new(synchronization.to_api)
  end

  def update_or_create_specific_step(classroom_id, discipline_api_id, used_steps, ieducar_updated_at)
    ActiveRecord::Base.transaction do
      discipline_id = Discipline.find_by(api_code: discipline_api_id).try(:id)

      if discipline_id
        specific_step = SpecificStep.find_or_create_by!(classroom_id: classroom_id, discipline_id: discipline_id)
        specific_step.update_attribute(:used_steps, used_steps)
      end
    end
  end
end
