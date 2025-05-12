# encoding: utf-8

class BaseMailer < ApplicationMailer
  default from: "Notificação i-Diário <#{Rails.application.secrets.NO_REPLY_ADDRESS}>".freeze
  default 'IsTransactional' => 'True'
  SKIP_DOMAINS = (Rails.application.secrets.EMAIL_SKIP_DOMAINS || []).split(',').flatten.freeze

  def skip_domains(emails)
    @recipient = emails.delete_if { |email|
      SKIP_DOMAINS.any? { |skip_domain| email.ends_with?(skip_domain) }
    }
  end
end
