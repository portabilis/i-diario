class NotifyByEmailDailyFrequencyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :send_emails, unique: :until_and_while_executing

  def perform(name, email, url, dates, classroom, unity)
    ReceiptMailer.notify_daily_frequency_success(name, email, url, dates, classroom, unity).deliver_now
  end
end
