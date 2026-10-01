namespace :entity_logo do
  desc 'Reprocessa em WebP redimensionado os brasões enviados antes da otimização (TENANT limita a uma rede)'
  task optimize: :environment do
    entities = ENV['TENANT'].present? ? Entity.where(name: ENV['TENANT']) : Entity.all

    # Operação cross-rede explícita: cada rede tem o próprio banco e o próprio brasão.
    entities.each do |entity|
      entity.using_connection do
        result = EntityLogoOptimizer.new(EntityConfiguration.first).optimize

        # O cabeçalho lê a configuração do Rails.cache; sem apagar, segue apontando para o arquivo antigo.
        Rails.cache.delete("EntityConfiguration##{entity.id}") if result == :optimized

        puts "#{entity.name}: #{result}"
      rescue StandardError => e
        puts "#{entity.name}: erro - #{e.class}: #{e.message}"
        Rails.logger.error("entity_logo:optimize entity_id=#{entity.id} #{e.class}: #{e.message}")
      end
    end
  end
end
