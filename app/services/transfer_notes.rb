class TransferNotes

  def initialize(transfer_note, options = {})
    @transfer_note = transfer_note
    @options = options
  end

  def destroy
    keep_all_daily_note_students_nil
  end

  private

  def keep_all_daily_note_students_nil
    @transfer_note.daily_note_students.update_all(transfer_note_id: nil, note: nil)
  end

end
