class DeleteDispensedExamsAndFrequenciesWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  queue: :low,
                  on_conflict: { client: :log, server: :reject }

  def perform(entity_id, student_enrollment_id, discipline_id, steps)
    Entity.find(entity_id).using_connection do
      DeleteDispensedExamsAndFrequenciesService.new(student_enrollment_id, discipline_id, steps).run!
    end
  end
end
