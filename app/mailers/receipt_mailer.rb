class ReceiptMailer < BaseMailer
  def notify_daily_frequency_success(user, url, date)
    @name = user.first_name
    @url = url

    return unless (email = user.email)

    skip_domains([email])

    mail(to: @recipient, subject: "Frequência do dia #{date} lançada com sucesso") if @recipient.present?
  end
end
