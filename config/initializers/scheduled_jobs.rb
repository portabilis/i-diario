Sidekiq::Cron::Job.destroy_all!
Sidekiq::Cron::Job.create(name: "I-Educar Synchronization - every 20 min", cron: "*/20 * * * *", class: "IeducarSynchronizerWorker") 
