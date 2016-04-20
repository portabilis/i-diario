class AddSchoolCalendarToAbsenceJustifications < ActiveRecord::Migration
  def change
    add_reference :absence_justifications, :school_calendar, index: true, foreign_key: true
  end
end
