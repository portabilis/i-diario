if Rails.env.production? || Rails.env.staging?
  Rails.application.config.middleware.use(ExceptionNotification::Rack,
    email: {
      email_prefix: "[novo-educacao-#{Rails.env}-exception] ",
      sender_address: 'Exception Notifier <no-reply@portabilis.com.br>',
      exception_recipients: %w(
          gabriel@portabilis.com.br
          victor@portabilis.com.br
          caroline@portabilis.com.br
          kellyn@portabilis.com.br
          eliezer@portabilis.com.br
          lucas@portabilis.com.br
        )

    }
  )
end
