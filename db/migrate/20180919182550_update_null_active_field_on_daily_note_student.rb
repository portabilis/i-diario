class UpdateNullActiveFieldOnDailyNoteStudent < ActiveRecord::Migration
  def change
    DailyNoteStudent.where(active: nil).each do |daily_note_student|
      daily_note_student.active = true
      daily_note_student.save
    end
  end
end
