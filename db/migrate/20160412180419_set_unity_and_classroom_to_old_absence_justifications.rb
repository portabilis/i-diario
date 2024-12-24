class SetUnityAndClassroomToOldAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
    update absence_justifications
      set unity_id = (select daily_frequencies.unity_id
                        from daily_frequencies
                       inner join daily_frequency_students on(daily_frequencies.id = daily_frequency_students.daily_frequency_id)
                       inner join classrooms on(daily_frequencies.classroom_id = classrooms.id)
                       where daily_frequency_students.student_id = absence_justifications.student_id
                         and EXTRACT(YEAR FROM absence_justifications.created_at) = classrooms.year
                       order by daily_frequencies.created_at DESC limit 1),

          classroom_id = (select daily_frequencies.classroom_id
                            from daily_frequencies
                           inner join daily_frequency_students on(daily_frequencies.id = daily_frequency_students.daily_frequency_id)
                           inner join classrooms on(daily_frequencies.classroom_id = classrooms.id)
                           where daily_frequency_students.student_id = absence_justifications.student_id
                             and EXTRACT(YEAR FROM absence_justifications.created_at) = classrooms.year
                           order by daily_frequencies.created_at DESC limit 1);
    SQL
  end
end
