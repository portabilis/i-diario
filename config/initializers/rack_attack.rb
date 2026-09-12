# Limita tentativas em endpoints sensíveis de autenticação.
#
# Escolha das chaves: escolas costumam acessar por trás de um único IP público, então limitar
# login por IP bloquearia a escola inteira. O login é limitado pela credencial informada (freia
# força bruta em uma conta sem punir o IP compartilhado). A recuperação de senha, de volume
# legítimo baixo, é limitada por IP.
class Rack::Attack
  # Recuperação de senha: no máximo 5 pedidos por IP a cada minuto.
  throttle('password-reset/ip', limit: 5, period: 60) do |req|
    req.ip if req.post? && req.path == '/usuarios/senha'
  end

  # Login: no máximo 10 tentativas por credencial a cada minuto.
  throttle('login/credential', limit: 10, period: 60) do |req|
    if req.post? && req.path == '/usuarios/logar'
      req.params.dig('user', 'credentials').to_s.downcase.strip.presence
    end
  end
end

Rails.application.config.middleware.use Rack::Attack
