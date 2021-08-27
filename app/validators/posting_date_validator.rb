class PostingDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value && record.classroom

    valid = PostingDateChecker.new(record.classroom, value).check

    unless valid
      record.errors.add(attribute, I18n.t('errors.messages.not_allowed_to_post_in_date'))
    end
  end
end
