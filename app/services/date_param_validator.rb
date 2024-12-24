class DateParamValidator
  include ActiveModel::Validations

  attr_accessor :date

  validates :date, presence: true
  validate :valid_date?, if: -> { date.present? }

  def initialize(date)
    @date = date
  end

  private

  def valid_date?
    return if parsed_date_values.count.eql?(3) && Date.valid_date?(*parsed_date_values)

    errors.add(:date, I18n.t('errors.messages.invalid_date'))
  end

  def parsed_date_values
    Date._parse(date).values
  end
end
