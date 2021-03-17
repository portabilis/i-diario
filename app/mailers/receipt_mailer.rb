class ReceiptMailer < BaseMailer
  def notify_daily_frequency_success(user, url, date)
    @name = user.first_name if user.first_name.present?
    @name = "#{@name} #{user.last_name}" if user.last_name.present?
    @name ||= user
    @url = url

    return unless (email = user.email)

    skip_domains([email])

    mail(to: @recipient, subject: "Frequência do dia #{date} lançada com sucesso") if @recipient.present?
  end
end
