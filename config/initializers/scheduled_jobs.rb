Sidekiq::Cron::Job.destroy_all!
if Rails.env.production?
  Sidekiq::Cron::Job.create(name: "I-Educar Synchronization - every 20 min", cron: "*/20 * * * *", class: "IeducarSynchronizerWorker")
end
