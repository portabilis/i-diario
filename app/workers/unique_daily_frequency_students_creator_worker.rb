class UniqueDailyFrequencyStudentsCreatorWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, daily_frequency_id, teacher_id)
    Entity.find(entity_id).using_connection do
      daily_frequency_students = {}
      daily_frequency = DailyFrequency.find(daily_frequency_id)
      daily_frequencies = DailyFrequency.by_classroom_id(daily_frequency.classroom_id)
                                        .by_frequency_date(daily_frequency.frequency_date)

      daily_frequencies.each do |current_daily_frequency|
        current_daily_frequency.students.each do |student|
          daily_frequency_students[student.student_id] ||= { present: false }
          daily_frequency_students[student.student_id][:present] ||= student.present
          daily_frequency_students[student.student_id].reverse_merge!(
            classroom_id: daily_frequency.classroom_id,
            frequency_date: daily_frequency.frequency_date
          )
        end
      end

      create_or_update_unique_daily_frequency_students(daily_frequency_students, teacher_id)
    end
  end

  private

  def create_or_update_unique_daily_frequency_students(daily_frequency_students, teacher_id)
    daily_frequency_students.each do |student_id, frequency_data|
      begin
        UniqueDailyFrequencyStudent.find_or_initialize_by(
          student_id: student_id,
          classroom_id: frequency_data[:classroom_id],
          frequency_date: frequency_data[:frequency_date]
        ).tap do |unique_daily_frequency_student|
          unique_daily_frequency_student.present = frequency_data[:present]
          unique_daily_frequency_student.absences_by |= [teacher_id.to_s] unless frequency_data[:present]

          unique_daily_frequency_student.save if unique_daily_frequency_student.changed?
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
