namespace :ieducar_api do
  desc "I-Educar API synchronization"
  task synchronize: :environment do
    Entity.all.each do |entity|
      IeducarSynchronizerWorker.perform_async(entity.id)
    end
  end
end
