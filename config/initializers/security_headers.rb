# Cabeçalhos de segurança enviados em todas as respostas. Os padrões do Rails 5.0
# (X-Frame-Options: SAMEORIGIN, X-Content-Type-Options: nosniff, X-XSS-Protection) já são
# enviados; aqui adicionamos os que faltam.
#
# A Content-Security-Policy fica em modo report-only: não bloqueia nada, apenas registra violações
# no console do navegador. Serve para mapear o que precisaria mudar antes de aplicar uma CSP
# de fato, sem risco de quebrar as telas atuais (que dependem de scripts e estilos inline).
Rails.application.config.action_dispatch.default_headers.merge!(
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  'Content-Security-Policy-Report-Only' => [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https:",
    "style-src 'self' 'unsafe-inline' https: fonts.googleapis.com",
    "img-src 'self' data: https:",
    "font-src 'self' data: https: fonts.gstatic.com use.fontawesome.com",
    "frame-ancestors 'self'",
    "object-src 'none'",
    "base-uri 'self'"
  ].join('; ')
)
