class ReceiptMailer < ActionMailer::Base
  default from: 'Notificação i-Diário <no@reply.com.br>'.freeze

  def notify_daily_frequency_success(user, url, date)
    @name = user.first_name if user.first_name.present?
    @name = "#{@name} #{user.last_name}" if user.last_name.present?
    @name ||= user
    @url = url

    mail(to: user.email, subject: "Frenquência do dia #{date} lançada com sucesso.")
  end
end
