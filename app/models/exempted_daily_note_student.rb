class ExemptedDailyNoteStudent
  attr_accessor :recovery_note

  def dependence?
    false
  end

  def note
    'D'
  end

  def recovery_note
    @recovery_note || 'D'
  end

  def has_recovery?
    false
  end
end
