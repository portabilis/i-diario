class ReceiptMailer < BaseMailer
  def notify_daily_frequency_success(name, email, url, date, classroom, unity)
    @name = name
    @email = email
    @url = url
    @classroom = classroom
    @unity = unity

    return unless @email

    skip_domains([@email])

    mail(to: @recipient, subject: "Frequência do dia #{date} lançada com sucesso") if @recipient.present?
  end

  def notify_daily_frequency_in_batch_success(name, email, url, dates, classroom, unity)
    @name = name
    @email = email
    @url = url
    @classroom = classroom
    @unity = unity
    @dates = dates

    return unless @email

    skip_domains([@email])

    mail(to: @recipient, subject: "Frequências foram lançadas com sucesso") if @recipient.present?
  end
end
