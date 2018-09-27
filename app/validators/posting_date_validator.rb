class PostingDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value && record.classroom
    old_value = record.send("#{attribute}_was")

    valid = [old_value, value].uniq.compact.all? do |val|
      PostingDateChecker.new(record.classroom, val).check
    end

    unless valid
      record.errors.add(attribute, I18n.t('errors.messages.not_allowed_to_post_in_date'))
    end
  end
end
