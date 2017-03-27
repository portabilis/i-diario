class StudentInRecoverySerializer < StudentSerializer
  attributes :average

  def average
    "%.#{@serialization_options[:number_of_decimal_places]}f" % student_recovery_average
  end

  private

  def student_recovery_average
    StudentRecoveryAverageCalculator.new(
      object,
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:school_calendar_step]
    ).recovery_average
  end
end
