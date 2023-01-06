class AddSchoolCalendarToAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    add_reference :absence_justifications, :school_calendar, index: true, foreign_key: true
  end
end
