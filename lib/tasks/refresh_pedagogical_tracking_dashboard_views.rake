desc 'Enfileira a atualização das views materializadas do acompanhamento pedagógico'
task refresh_pedagogical_tracking_views: :environment do
  # A atualização roda em jobs encadeados (um por entidade) para que a falha em
  # uma base não impeça a atualização das demais.
  entity_ids = Entity.active.order(:id).pluck(:id)

  next if entity_ids.empty?

  first_entity_id, *remaining_entity_ids = entity_ids

  RefreshPedagogicalTrackingViewsWorker.perform_async(first_entity_id, remaining_entity_ids)
end
