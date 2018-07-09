class NullDailyNoteStudent
  attr_accessor :recovery_note

  def dependence?
    false
  end

  def note
    'N'
  end

  def recovery_note
    @recovery_note || 'N'
  end

  def has_recovery?
    false
  end
end
