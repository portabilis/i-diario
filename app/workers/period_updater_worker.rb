class PeriodUpdaterWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  queue: :low,
                  on_conflict: { client: :log, server: :reject }

  def perform(entity_id, classroom_id, old_period, new_period)
    Entity.find(entity_id).using_connection do
      PeriodUpdaterService.update_period_dependents(classroom_id, old_period, new_period)
    end
  end
end
