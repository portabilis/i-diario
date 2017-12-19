namespace :entity do
  desc "Delete frequencies from inactive students"
  task delete_frequency_from_inactive_students: :environment do
    name = ENV['NAME']
    entities = name == 'all' ? Entity.all : Entity.where(name: name)
    if entities
      entities.each do |entity|
        entity.using_connection do
          daily_frequency_students_to_delete = DailyFrequencyStudent.find_by_sql "SELECT daily_frequency_students.id from daily_frequency_students
                                                                                    inner join daily_frequencies on daily_frequency_students.daily_frequency_id = daily_frequencies.id
                                                                                    inner join students on daily_frequency_students.student_id = students.id
                                                                                    inner join student_enrollments on student_enrollments.student_id = students.id
                                                                                    inner join student_enrollment_classrooms on student_enrollment_classrooms.student_enrollment_id = student_enrollments.id
                                                                                  where student_enrollment_classrooms.left_at <> '' and daily_frequencies.frequency_date > date(student_enrollment_classrooms.left_at)
                                                                                  and daily_frequency_students.present is not null"

          daily_frequency_students = DailyFrequencyStudent.where(id: daily_frequency_students_to_delete)
          p "#{daily_frequency_students_to_delete.count} frequencias deletadas"
          daily_frequency_students.destroy_all
        end
      end
    end
  end
end
