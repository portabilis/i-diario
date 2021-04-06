if Rails.env.production? || Rails.env.staging?
  ActionMailer::Base.delivery_method = :smtp

  ActionMailer::Base.smtp_settings = {
    enable_starttls_auto: true,
    address: Rails.application.secrets.SMTP_ADDRESS,
    port: Rails.application.secrets.SMTP_PORT,
    domain: Rails.application.secrets.SMTP_DOMAIN,
    authentication: 'plain',
    user_name: Rails.application.secrets.SMTP_USER_NAME,
    password: Rails.application.secrets.SMTP_PASSWORD
  }

  ActionMailer::Base.default from: "Notificação i-Diário <#{Rails.application.secrets.NO_REPLY_ADDRESS}>"
end
