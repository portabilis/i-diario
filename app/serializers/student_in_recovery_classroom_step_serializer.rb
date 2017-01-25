class StudentInRecoveryClassroomStepSerializer < StudentSerializer
  attributes :average

  def average
    # FIXME: Need to find a better solution to format the scores based on the configuration. :(
    "%.#{@serialization_options[:number_of_decimal_places]}f" % object.average(
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:school_calendar_classroom_step]
    )
  end
end
