class IeducarResponseDecorator < HashDecorator
  def any_error_message?
    any_error_msg
  end

  def error_message(information)
    return '' unless error?
    return I18n.t('ieducar_api.error.messages.post_error') unless known_error?

    full_error_message(information)
  end

  def full_error_message(information)
    return '' unless error?

    "#{information} #{error.message}"
  end

  def known_error?
    return false unless error?

    IeducarErrorMessages.key_for(error.code)
  end

  private

  def error?
    key_exist?('error')
  end
end
