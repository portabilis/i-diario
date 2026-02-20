# frozen_string_literal: true

# Mailer customizado do Devise que herda do BaseMailer para aplicar filtro de
# domínio (skip_domains) e headers de e-mail transacional (IsTransactional).
class DeviseCustomMailer < BaseMailer
  include Devise::Mailers::Helpers

  def reset_password_instructions(record, token, opts = {})
    @token = token
    skip_domains([record.email])
    return unless @recipient.present?

    devise_mail(record, :reset_password_instructions, opts.merge(to: @recipient))
  end

  def unlock_instructions(record, token, opts = {})
    @token = token
    skip_domains([record.email])
    return unless @recipient.present?

    devise_mail(record, :unlock_instructions, opts.merge(to: @recipient))
  end

  protected

  # Garante que os templates existentes em app/views/devise/mailer/ sejam encontrados
  def template_paths
    ['devise/mailer']
  end
end
