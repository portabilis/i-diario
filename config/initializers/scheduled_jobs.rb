Sidekiq::Cron::Job.destroy_all!
if Rails.env.staging? || Rails.env.development?
  Sidekiq::Cron::Job.create(name: "I-Educar Synchronization - every 2 min", cron: "*/2 * * * *", class: "IeducarSynchronizerWorker")
elsif Rails.env.production?
  Sidekiq::Cron::Job.create(name: "I-Educar Synchronization - every 10 min", cron: "*/10 * * * *", class: "IeducarSynchronizerWorker")
end
