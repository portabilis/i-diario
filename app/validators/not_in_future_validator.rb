class NotInFutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.present? && record.errors[attribute].none?

    if Date.parse(value.to_s) > Time.zone.today
      record.errors.add(attribute, I18n.t('errors.messages.not_in_future'))
    end
  end
end
