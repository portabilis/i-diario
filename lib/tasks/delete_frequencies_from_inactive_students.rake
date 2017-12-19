namespace :entity do
  desc "Delete frequencies from inactive students"
  task delete_frequency_from_inactive_students: :environment do
    name = ENV['NAME']
    entity = Entity.find_by_name(name)
    if entity
      entity.using_connection do
        daily_frequency_students_to_delete = DailyFrequencyStudent.find_by_sql "SELECT dfs.id from daily_frequency_students dfs
                                                                                    inner join daily_frequencies df on dfs.daily_frequency_id = df.id
                                                                                    inner join students s on dfs.student_id = s.id
                                                                                    inner join student_enrollments se on se.student_id = s.id
                                                                                    inner join student_enrollment_classrooms sec on sec.student_enrollment_id = se.id
                                                                                where sec.left_at <> '' and df.frequency_date > date(sec.left_at) and dfs.present is not null
                                                                                order by s.name, df.frequency_date"

        daily_frequency_students = DailyFrequencyStudent.where(id: daily_frequency_students_to_delete)
        p "#{daily_frequency_students_to_delete.count} frequencias deletadas"
        daily_frequency_students.destroy_all
      end
    end
  end
end
