class NullDailyNoteStudent
  attr_accessor :recovery_note

  def dependence?
    false
  end

  def note
    StudentSituationMarkers::NOT_ENROLLED
  end

  def recovery_note
    @recovery_note || StudentSituationMarkers::NOT_ENROLLED
  end

  def has_recovery?
    false
  end
end
