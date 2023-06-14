class AddUniqueIndexOnDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    #FIXME Não utilizar model em migration
    daily_note_students = DailyNoteStudent.find_by_sql(
      <<-SQL
        SELECT * FROM daily_note_students d
        WHERE (
          SELECT COUNT(*) FROM daily_note_students f
          WHERE f.daily_note_id = d.daily_note_id AND f.student_id = d.student_id
        ) > 1
        ORDER BY daily_note_id, student_id, note;
      SQL
    )
    grouped = daily_note_students.group_by { |d| [d.daily_note_id, d.student_id] }
    grouped.each do |g|
      sorted = g.last.sort_by { |d| d.updated_at }
      sorted.each { |d|
        unless d == sorted.last
          d.without_auditing do
            d.destroy!
          end
        end
      }
    end

    add_index :daily_note_students, [:daily_note_id, :student_id], unique: true
  end
end
