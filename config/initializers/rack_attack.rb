# Limita tentativas em endpoints sensíveis de autenticação.
#
# Escolha das chaves: escolas costumam acessar por trás de um único IP público, então um limite
# apertado por IP bloquearia a escola inteira. Login e recuperação de senha são limitados pela
# conta informada (freia o abuso contra uma conta sem punir o IP compartilhado); o limite por IP
# da recuperação de senha é folgado o bastante para um laboratório em uso e só segura quem
# varre muitos e-mails.
#
# A gem registra o middleware sozinha pelo Railtie; não há `middleware.use` aqui.
class Rack::Attack
  # As rotas do Devise ficam dentro de `localized`, que gera um caminho por idioma
  # (/usuarios/logar e /users/sign_in) e aceita extensão de formato. Comparar pela action
  # de destino cobre todas as variantes, inclusive idiomas adicionados depois.
  class Request < ::Rack::Request
    def routed_to?(controller_action)
      post? && auth_route == controller_action
    end

    private

    def auth_route
      return @auth_route if defined?(@auth_route)

      route = Rails.application.routes.recognize_path(path, method: :post)
      @auth_route = "#{route[:controller]}##{route[:action]}"
    rescue ActionController::RoutingError
      @auth_route = nil
    end
  end

  # Recuperação de senha: no máximo 5 pedidos por e-mail a cada minuto. Como no login, o host
  # entra na chave porque cada rede tem o próprio cadastro de usuários.
  throttle('password-reset/email', limit: 5, period: 60) do |req|
    next unless req.routed_to?('users/passwords#create')

    email = req.params.dig('user', 'email').to_s.downcase.strip.presence
    "#{req.host}:#{email}" if email
  end

  # Recuperação de senha: no máximo 30 pedidos por IP a cada minuto.
  throttle('password-reset/ip', limit: 30, period: 60) do |req|
    req.ip if req.routed_to?('users/passwords#create')
  end

  # Login: no máximo 10 tentativas por credencial a cada minuto. Cada rede tem o próprio
  # cadastro de usuários, então o host entra na chave para uma rede não bloquear a outra.
  throttle('login/credential', limit: 10, period: 60) do |req|
    next unless req.routed_to?('users/sessions#create')

    credentials = req.params.dig('user', 'credentials').to_s.downcase.strip.presence
    "#{req.host}:#{credentials}" if credentials
  end

  self.throttled_responder = lambda do |req|
    match_data = req.env['rack.attack.match_data']
    retry_after = match_data[:period] - (match_data[:epoch_time] % match_data[:period])
    message = ERB::Util.html_escape(I18n.t('rack_attack.throttled'))
    body = <<~HTML
      <!DOCTYPE html>
      <html lang="pt-BR">
        <head><meta charset="utf-8"><title>#{message}</title></head>
        <body><p>#{message}</p><p><a href="/">#{I18n.t('rack_attack.back')}</a></p></body>
      </html>
    HTML

    [429, { 'Content-Type' => 'text/html; charset=utf-8', 'Retry-After' => retry_after.to_s }, [body]]
  end
end
