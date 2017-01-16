class StudentAvaliationExemptionQuery
  def initialize(student, avaliation)
    @student = student
  end

  def is_exempted(avaliation)
    AvaliationExemption
      .by_student(student)
      .by_avaliation(avaliation)
      .any?
  end

  private

  attr_accessor :student, :avaliation
end
