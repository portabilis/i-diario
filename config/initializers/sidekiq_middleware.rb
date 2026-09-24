# Registra o reset de contexto thread-local por job (ver
# app/middleware/thread_context_reset_middleware.rb). prepend em vez de add:
# como middleware mais externo, o reset roda depois dos middlewares internos
# desempilharem, e nenhum deles enxerga contexto já zerado.
Sidekiq.configure_server do |config|
  config.server_middleware { |chain| chain.prepend ThreadContextResetMiddleware }
end
