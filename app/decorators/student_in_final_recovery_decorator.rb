class StudentInFinalRecoveryDecorator
  include Decore
  include Decore::Proxy

  attr_accessor :needed_score

  def needed_score=(value)
    @needed_score = value
  end

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
