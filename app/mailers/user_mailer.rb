class UserMailer < ActionMailer::Base
  default from: "Notificação i-Diário <#{Rails.application.secrets.NO_REPLY_ADDRESS}>"

  def notify_activation(user_email, user_name, user_logged_as, domain)
    return unless user_email

    skip_domains = Rails.application.secrets.EMAIL_SKIP_DOMAINS.split(',')

    return if skip_domains.any? { |skip_domain| user_email.ends_with?(skip_domain) }

    @user_name = user_name
    @user_logged_as = user_logged_as
    @domain = domain

    mail to: user_email, subject: 'Conta de acesso ativada'
  end
end
