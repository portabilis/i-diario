class ExemptedDailyNoteStudent
  attr_accessor :recovery_note

  def dependence?
    false
  end

  def note
    StudentSituationMarkers::EXEMPTED
  end

  def recovery_note
    @recovery_note || StudentSituationMarkers::EXEMPTED
  end

  def has_recovery?
    false
  end
end
