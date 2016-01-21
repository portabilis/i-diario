class NotInFutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value

    if value > Time.zone.today
      record.errors.add(attribute, I18n.t('errors.messages.not_in_future'))
    end
  end
end
