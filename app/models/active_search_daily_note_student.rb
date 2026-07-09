class ActiveSearchDailyNoteStudent
  attr_accessor :recovery_note

  def dependence?
    false
  end

  def note
    StudentSituationMarkers::ACTIVE_SEARCH
  end

  def recovery_note
    @recovery_note || StudentSituationMarkers::ACTIVE_SEARCH
  end

  def has_recovery?
    false
  end
end
