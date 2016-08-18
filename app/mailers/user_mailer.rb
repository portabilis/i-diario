class UserMailer < ActionMailer::Base

  def notify_actived(user, entity)
    @user = user
    @entity = entity

    mail to: user.email, subject: "Conta de acesso ativada"
  end
end
