class ActiveSearchDailyNoteStudent
  attr_accessor :recovery_note

  def dependence?
    false
  end

  def note
    'BA'
  end

  def recovery_note
    @recovery_note || 'BA'
  end

  def has_recovery?
    false
  end
end
