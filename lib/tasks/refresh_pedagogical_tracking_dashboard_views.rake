desc 'Enfileira a atualização das views materializadas do acompanhamento pedagógico'
task refresh_pedagogical_tracking_views: :environment do
  # O enfileiramento pode não levantar erro com a fila indisponível: o job ficaria
  # em memória e seria perdido no fim da rake, sem nenhum sinal. O ping falha alto.
  Sidekiq.redis(&:ping)

  # Um job por entidade, encadeados, para que a falha em uma base não impeça as demais.
  RefreshPedagogicalTrackingViewsWorker.enqueue_next(Entity.active.order(:id).pluck(:id))
end
