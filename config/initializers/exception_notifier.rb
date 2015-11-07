if Rails.env.production? || Rails.env.staging?
  Rails.application.config.middleware.use(ExceptionNotification::Rack,
    email: {
      email_prefix: "[novo-educacao-#{Rails.env}-exception] ",
      sender_address: 'Exception Notifier <no-reply@portabilis.com.br>',
      exception_recipients: %w(
          joao@portabilis.com.br
          marcelo@portabilis.com.br
          matheus@portabilis.com.br
        )

    }
  )
end
