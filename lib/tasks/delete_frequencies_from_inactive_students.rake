namespace :entity do
  desc "Delete frequencies from inactive students"
  task delete_frequency_from_inactive_students: :environment do
    name = ENV['NAME']
    entities = name == 'all' ? Entity.active : Entity.where(name: name)
    if entities
      entities.each do |entity|
        entity.using_connection do
          daily_frequency_students_to_delete = DailyFrequencyStudent.joins(:daily_frequency, student: { student_enrollments: :student_enrollment_classrooms })
                                                                    .where("student_enrollment_classrooms.left_at <> ''
                                                                            and daily_frequencies.frequency_date > date(student_enrollment_classrooms.left_at)
                                                                            and daily_frequency_students.present is not null")

          p "#{daily_frequency_students_to_delete.count} frequencias deletadas"
          daily_frequency_students_to_delete.destroy_all
        end
      end
    end
  end
end
