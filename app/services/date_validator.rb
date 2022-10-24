class DateValidator
  include ActiveModel::Validations

  attr_accessor :date

  validates :date, presence: true
  validate :valid_date?, if: -> { date.present? }

  def initialize(date)
    @date = date
  end

  private

  def valid_date?
    errors.add(:date, I18n.t('errors.messages.invalid_date')) unless Date.valid_date?(*Date._parse(date).values)
  end
end
