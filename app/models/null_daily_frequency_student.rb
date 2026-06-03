class NullDailyFrequencyStudent
  def dependence?
    false
  end

  def present
    true
  end

  def to_s
    StudentSituationMarkers::NOT_ENROLLED
  end
end
