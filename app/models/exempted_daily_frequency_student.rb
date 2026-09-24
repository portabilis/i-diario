class ExemptedDailyFrequencyStudent
  def dependence?
    false
  end

  def present
    true
  end

  def to_s
    StudentSituationMarkers::EXEMPTED
  end
end
