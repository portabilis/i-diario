namespace :entity_configuration_cache do
  desc 'Clears EntityConfiguration cache after database restore'
  task clear: :environment do
    begin
      Entity.connect ENV['TENANT'].to_sym
      entity_id = Entity.current.id

      Rails.cache.delete("EntityConfiguration##{entity_id}")

      puts "Cache cleared for entity ID: #{entity_id}"
    rescue StandardError => e
      puts "Error clearing cache for tenant #{ENV['TENANT']}: #{e.message}"
    end
  end
end
