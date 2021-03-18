# encoding: utf-8

class BaseMailer < ActionMailer::Base
  default from: "Notificação i-Diário <#{Rails.application.secrets.NO_REPLY_ADDRESS}>".freeze
  SKIP_DOMAINS = (Rails.application.secrets.EMAIL_SKIP_DOMAINS || []).split(',').freeze

  def skip_domains(emails)
    @recipient = emails.delete_if { |email|
      SKIP_DOMAINS.any? { |skip_domain| email.ends_with?(skip_domain) }
    }
  end
end
