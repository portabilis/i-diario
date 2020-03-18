class PeriodUpdaterWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, classroom_id, old_period, new_period)
    Entity.find(entity_id).using_connection do
      PeriodUpdaterService.update_period_dependents(classroom_id, old_period, new_period)
    end
  end
end
