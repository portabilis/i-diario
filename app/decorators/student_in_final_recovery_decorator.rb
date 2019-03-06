class StudentInFinalRecoveryDecorator
  include Decore
  include Decore::Proxy

  delegate :to_s, to: :component

  attr_writer :needed_score

  def needed_score
    I18n::Alchemy::NumericParser.localize(@needed_score)
  end

  def self.primary_key
    Student.primary_key
  end

  def is_a?(klass)
    super || component.is_a?(klass)
  end
end
