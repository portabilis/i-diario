namespace :ieducar_api do
  desc "I-Educar API synchronization"
  task synchronize: :environment do
    IeducarSynchronizerWorker.new.perform
  end
end
