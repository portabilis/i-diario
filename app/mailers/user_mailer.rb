class UserMailer < ActionMailer::Base
  default from: 'Notificação i-Diário <no@reply.com.br>'

  def notify_activation(user_email, user_name, user_logged_as, domain)
    return unless user_email

    @user_name = user_name
    @user_logged_as = user_logged_as
    @domain = domain

    mail to: user_email, subject: 'Conta de acesso ativada'
  end
end
