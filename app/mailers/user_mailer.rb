class UserMailer < ActionMailer::Base
  default from: "no-reply@portabilis.com.br"

  def notify_actived(user, entity)
    @user = user
    @entity = entity

    mail to: user.email, subject: "Conta de acesso ativada"
  end
end
