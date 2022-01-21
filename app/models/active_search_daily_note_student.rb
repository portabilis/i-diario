class ActiveSearchDailyNoteStudent
  attr_accessor :recovery_note

  def dependence?
    false
  end

  def note
    'B'
  end

  def recovery_note
    @recovery_note || 'B'
  end

  def has_recovery?
    false
  end
end
