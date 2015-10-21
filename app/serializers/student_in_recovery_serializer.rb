class StudentInRecoverySerializer < StudentSerializer
  attributes :average

  def average
    object.average(
      @serialization_options[:discipline_id],
      @serialization_options[:school_calendar_step_id]
    )    
  end
end
