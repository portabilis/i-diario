class StudentInRecoveryClassroomStepSerializer < StudentSerializer
  attributes :average

  def average
    "%.#{@serialization_options[:number_of_decimal_places]}f" % student_recovery_average
  end

  def student_recovery_average
    StudentRecoveryAverageCalculator.new(
      object,
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:school_calendar_classroom_step]
    ).recovery_average
  end
end
