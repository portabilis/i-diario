class ActiveSearchFrequencyStudent
  def dependence?
    false
  end

  def present
    true
  end

  def to_s
    StudentSituationMarkers::ACTIVE_SEARCH
  end
end
