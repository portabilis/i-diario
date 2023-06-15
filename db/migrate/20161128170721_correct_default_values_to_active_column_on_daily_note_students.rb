class CorrectDefaultValuesToActiveColumnOnDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE daily_note_students SET active = (
       CASE WHEN daily_note_students.id IN(
        SELECT dns.id
          FROM daily_notes dn
          INNER JOIN avaliations a ON(dn.avaliation_id = a.id)
          INNER JOIN daily_note_students dns ON(dn.id = dns.daily_note_id)
          INNER JOIN student_enrollments se ON(dns.student_id = se.student_id)
          INNER JOIN student_enrollment_classrooms sec ON(sec.classroom_id = a.classroom_id AND se.id = sec.student_enrollment_id)
          WHERE (a.test_date::varchar >= sec.joined_at::varchar AND a.test_date::varchar <= sec.left_at::varchar
            OR (a.test_date::varchar >= sec.joined_at AND coalesce(sec.left_at) = ''))) then TRUE else FALSE end
       );
    SQL
  end
end
