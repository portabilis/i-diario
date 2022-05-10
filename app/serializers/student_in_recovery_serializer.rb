class StudentInRecoverySerializer < StudentSerializer
  attributes :average, :exempted_from_discipline

  def average
    return if student_recovery_average.blank?

    "%.#{@serialization_options[:number_of_decimal_places]}f" % student_recovery_average
  end

  private

  def student_recovery_average
    StudentRecoveryAverageCalculator.new(
      object,
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:step]
    ).recovery_average
  end
end
