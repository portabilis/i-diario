class UserMailer < BaseMailer
  def notify_activation(user_email, user_name, user_logged_as, domain)
    return unless user_email

    skip_domains([user_email])

    @user_name = user_name
    @user_logged_as = user_logged_as
    @domain = domain

    mail(to: @recipient, subject: 'Conta de acesso ativada') if @recipient.present?
  end

  def by_csv(login, first_name, email, password, entity_url)
    @login = login
    @name = first_name
    @recipient = email
    @password = password
    @entity_url = entity_url

    mail(to: @recipient, subject: 'Bem vindo ao i-Diário!') if @recipient.present?
  end

  def reset_password(login, first_name, email, password)
    @login = login
    @name = first_name
    @recipient = email
    @password = password

    mail(to: @recipient, subject: 'Redefinição de senha i-Diário!') if @recipient.present?
  end
end
